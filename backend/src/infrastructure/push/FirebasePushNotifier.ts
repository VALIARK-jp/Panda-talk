import type { Notification, UUID } from '../../domain/entities/index'
import type { IUserRepository } from '../../domain/repositories/IUserRepository'
import type { IPushTokenRepository } from '../../domain/repositories/IPushTokenRepository'
import type { Env } from '../env'
import { SupabaseRestClient } from '../supabase/SupabaseRestClient'

type FirebaseServiceAccount = {
  project_id?: string
  client_email?: string
  private_key?: string
  token_uri?: string
}

type NotificationSettingsRow = {
  likes_enabled: boolean
  comments_enabled: boolean
  friend_requests_enabled: boolean
  friend_accepted_enabled: boolean
}

type PushContent = {
  title: string
  body: string
}

type CachedAccessToken = {
  token: string
  expiresAtMs: number
}

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token'
const FCM_MESSAGE_ENDPOINT =
  'https://fcm.googleapis.com/v1/projects/{projectId}/messages:send'

export class FirebasePushNotifier {
  constructor(
    private readonly env: Env,
    private readonly client: SupabaseRestClient,
    private readonly userRepo: IUserRepository,
    private readonly pushTokenRepo: IPushTokenRepository
  ) {}

  private cachedAccessToken: CachedAccessToken | null = null

  async notify(notification: Notification): Promise<void> {
    const tokens = await this.pushTokenRepo.listByUser(notification.userId)
    console.log('[push] notify start', {
      notificationId: notification.id,
      userId: notification.userId,
      type: notification.type,
      tokenCount: tokens.length,
    })
    if (tokens.length === 0) return

    if (!(await this.shouldSend(notification.userId, notification.type))) {
      console.log('[push] skipped by settings', {
        notificationId: notification.id,
        userId: notification.userId,
        type: notification.type,
      })
      return
    }

    const content = await this.buildContent(notification)
    const results = await Promise.allSettled(
      tokens.map((token) => this.sendToToken(token.token, token.platform, notification, content))
    )

    for (const result of results) {
      if (result.status === 'rejected') {
        console.warn('push send failed:', result.reason)
      }
    }
    console.log('[push] notify done', {
      notificationId: notification.id,
      userId: notification.userId,
      type: notification.type,
      failedCount: results.filter((result) => result.status === 'rejected').length,
    })
  }

  private async shouldSend(
    userId: UUID,
    type: Notification['type']
  ): Promise<boolean> {
    if (type === 'test') return true

    let rows: NotificationSettingsRow[] = []
    try {
      rows = await this.client.get<NotificationSettingsRow[]>(
        'panda_notification_settings',
        {
          select: '*',
          user_id: `eq.${userId}`,
          limit: 1,
        }
      )
    } catch {
      rows = await this.client.get<NotificationSettingsRow[]>(
        'panda_notification_settings',
        {
          select: 'user_id,likes_enabled,comments_enabled,friend_requests_enabled',
          user_id: `eq.${userId}`,
          limit: 1,
        }
      )
    }
    const settings = rows[0]
    if (!settings) return true

    switch (type) {
      case 'like':
        return settings.likes_enabled
      case 'comment':
        return settings.comments_enabled
      case 'friend_request':
        return settings.friend_requests_enabled
      case 'friend_accepted':
        return settings.friend_accepted_enabled ?? settings.friend_requests_enabled
      default:
        return false
    }
  }

  private async buildContent(notification: Notification): Promise<PushContent> {
    const actorName =
      notification.actorId != null
        ? (await this.userRepo.findById(notification.actorId))?.name ?? '誰か'
        : '誰か'

    switch (notification.type) {
      case 'like':
        return {
          title: 'いいね通知',
          body: `${actorName}さんがあなたの質問にいいねしました`,
        }
      case 'comment':
        return {
          title: 'コメント通知',
          body: `${actorName}さんがコメントしました`,
        }
      case 'friend_request':
        return {
          title: '友達申請',
          body: `${actorName}さんから友達申請が届きました`,
        }
      case 'friend_accepted':
        return {
          title: '友達になりました',
          body: `${actorName}さんと友達になりました`,
        }
      case 'new_match':
        return {
          title: '新しいマッチ',
          body: 'あなたと相性の良い人が現れました',
        }
      case 'group_created':
        return {
          title: 'グループ作成',
          body: '新しいパンダ部屋が作られました',
        }
      case 'test':
        return {
          title: '通知テスト',
          body: '通知の受信経路が正常に動作しています',
        }
      default:
        return {
          title: '通知',
          body: '新しい通知があります',
        }
    }
  }

  private async sendToToken(
    token: string,
    platform: string,
    notification: Notification,
    content: PushContent
  ): Promise<void> {
    const accessToken = await this.getAccessToken()
    const projectId = this.getProjectId()
    const endpoint = FCM_MESSAGE_ENDPOINT.replace('{projectId}', projectId)
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: content,
          data: {
            notificationId: notification.id,
            type: notification.type,
            targetId: notification.targetId ?? '',
            platform,
          },
          android: {
            priority: 'HIGH',
          },
          apns: {
            headers: {
              'apns-push-type': 'alert',
              'apns-priority': '10',
            },
            payload: {
              aps: {
                sound: 'default',
              },
            },
          },
        },
      }),
    })

    if (!response.ok) {
      const text = await response.text()
      console.error('[push] fcm send failed', {
        notificationId: notification.id,
        userId: notification.userId,
        tokenPrefix: token.slice(0, 8),
        platform,
        status: response.status,
        body: text,
      })
      throw new Error(`FCM send failed (${response.status}): ${text}`)
    }
    console.log('[push] fcm send ok', {
      notificationId: notification.id,
      userId: notification.userId,
      tokenPrefix: token.slice(0, 8),
      platform,
    })
  }

  private getProjectId(): string {
    const serviceAccount = this.getServiceAccount()
    const projectId = this.env.FIREBASE_PROJECT_ID?.trim() || serviceAccount.project_id?.trim() || ''
    if (!projectId) {
      throw new Error('FIREBASE_PROJECT_ID is missing')
    }
    return projectId
  }

  private getServiceAccount(): FirebaseServiceAccount {
    const raw = this.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim()
    if (!raw) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is missing')
    }
    return JSON.parse(raw) as FirebaseServiceAccount
  }

  private async getAccessToken(): Promise<string> {
    const now = Date.now()
    if (this.cachedAccessToken && this.cachedAccessToken.expiresAtMs > now + 60_000) {
      return this.cachedAccessToken.token
    }

    const serviceAccount = this.getServiceAccount()
    const clientEmail = serviceAccount.client_email?.trim()
    const privateKey = serviceAccount.private_key?.trim()
    if (!clientEmail || !privateKey) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON must include client_email and private_key')
    }

    const assertion = await this.createAssertion(clientEmail, privateKey)
    const tokenUri = serviceAccount.token_uri?.trim() || DEFAULT_TOKEN_URI
    const response = await fetch(tokenUri, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    })

    if (!response.ok) {
      const text = await response.text()
      throw new Error(`Firebase access token fetch failed (${response.status}): ${text}`)
    }

    const data = (await response.json()) as { access_token?: string; expires_in?: number }
    if (!data.access_token) {
      throw new Error('Firebase access token response missing access_token')
    }

    const expiresInMs = Math.max(0, (data.expires_in ?? 3600) * 1000)
    this.cachedAccessToken = {
      token: data.access_token,
      expiresAtMs: now + expiresInMs,
    }
    return data.access_token
  }

  private async createAssertion(clientEmail: string, privateKey: string): Promise<string> {
    const header = base64UrlEncodeJson({
      alg: 'RS256',
      typ: 'JWT',
    })
    const now = Math.floor(Date.now() / 1000)
    const payload = base64UrlEncodeJson({
      iss: clientEmail,
      sub: clientEmail,
      aud: DEFAULT_TOKEN_URI,
      scope: FCM_SCOPE,
      iat: now,
      exp: now + 3600,
    })
    const unsignedToken = `${header}.${payload}`
    const key = await importPrivateKey(privateKey)
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      key,
      new TextEncoder().encode(unsignedToken)
    )
    return `${unsignedToken}.${base64UrlFromBytes(signature)}`
  }

  dispose(): void {
    this.cachedAccessToken = null
  }
}

async function importPrivateKey(privateKeyPem: string): Promise<CryptoKey> {
  const der = pemToArrayBuffer(privateKeyPem)
  return crypto.subtle.importKey(
    'pkcs8',
    der,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  )
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem.replace(/\\n/g, '\n').trim()
  const base64 = normalized
    .split('\n')
    .filter((line) => !line.startsWith('-----'))
    .join('')
    .trim()
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

function base64UrlEncodeJson(value: unknown): string {
  return base64UrlFromString(JSON.stringify(value))
}

function base64UrlFromString(value: string): string {
  const bytes = new TextEncoder().encode(value)
  return base64UrlFromBytes(bytes)
}

function base64UrlFromBytes(value: BufferSource): string {
  const bytes = value instanceof Uint8Array ? value : new Uint8Array(value as ArrayBuffer)
  let binary = ''
  for (const byte of bytes) {
    binary += String.fromCharCode(byte)
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '')
}
