type QueryValue = string | number | boolean | null | undefined

type RequestOptions = {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE'
  body?: unknown
  prefer?: string
}

export class SupabaseRestClient {
  private readonly restUrl: string

  constructor(
    supabaseUrl: string,
    private readonly serviceRoleKey: string
  ) {
    this.restUrl = `${supabaseUrl.replace(/\/$/, '')}/rest/v1`
  }

  async get<T>(resource: string, query: Record<string, QueryValue> = {}): Promise<T> {
    return this.request<T>(resource, query)
  }

  async insert<T>(resource: string, body: unknown): Promise<T[]> {
    return this.request<T[]>(resource, {}, {
      method: 'POST',
      body,
      prefer: 'return=representation',
    })
  }

  async update<T>(
    resource: string,
    query: Record<string, QueryValue>,
    body: unknown
  ): Promise<T[]> {
    return this.request<T[]>(resource, query, {
      method: 'PATCH',
      body,
      prefer: 'return=representation',
    })
  }

  async delete(resource: string, query: Record<string, QueryValue>): Promise<void> {
    await this.request(resource, query, {
      method: 'DELETE',
      prefer: 'return=minimal',
    })
  }

  private async request<T>(
    resource: string,
    query: Record<string, QueryValue> = {},
    options: RequestOptions = {}
  ): Promise<T> {
    const params = new URLSearchParams()
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined || value === null) continue
      params.set(key, String(value))
    }

    const queryString = params.toString()
    const response = await fetch(
      `${this.restUrl}/${resource}${queryString ? `?${queryString}` : ''}`,
      {
        method: options.method ?? 'GET',
        headers: {
          apikey: this.serviceRoleKey,
          Authorization: `Bearer ${this.serviceRoleKey}`,
          'Content-Type': 'application/json',
          ...(options.prefer ? { Prefer: options.prefer } : {}),
        },
        body: options.body === undefined ? undefined : JSON.stringify(options.body),
      }
    )

    if (!response.ok) {
      const message = await response.text()
      throw Object.assign(new Error(message || 'Supabase request failed'), {
        code: 'SUPABASE_ERROR',
      })
    }

    if (response.status === 204) {
      return undefined as T
    }

    return response.json() as Promise<T>
  }
}
