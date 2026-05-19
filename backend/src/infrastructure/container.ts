import { MockUserRepository } from './mock/MockUserRepository'
import { MockQuestionRepository } from './mock/MockQuestionRepository'
import { MockAnswerRepository } from './mock/MockAnswerRepository'
import { MockFriendshipRepository } from './mock/MockFriendshipRepository'
import { MockMatchRepository } from './mock/MockMatchRepository'
import { MockCommentRepository } from './mock/MockCommentRepository'
import { MockQuestionLikeRepository } from './mock/MockQuestionLikeRepository'
import { MockCommentLikeRepository } from './mock/MockCommentLikeRepository'
import { MockNotificationRepository } from './mock/MockNotificationRepository'
import { MockGroupRepository } from './mock/MockGroupRepository'
import { MockMessageRepository } from './mock/MockMessageRepository'
import { MockDirectMessageRepository } from './mock/MockDirectMessageRepository'

import { SupabaseRestClient } from './supabase/SupabaseRestClient'
import { SupabaseUserRepository } from './supabase/repositories/SupabaseUserRepository'
import { SupabaseQuestionRepository } from './supabase/repositories/SupabaseQuestionRepository'
import { SupabaseAnswerRepository } from './supabase/repositories/SupabaseAnswerRepository'
import { SupabaseMatchRepository } from './supabase/repositories/SupabaseMatchRepository'
import { SupabaseFriendshipRepository } from './supabase/repositories/SupabaseFriendshipRepository'
import { SupabaseCommentRepository } from './supabase/repositories/SupabaseCommentRepository'
import { SupabaseQuestionLikeRepository } from './supabase/repositories/SupabaseQuestionLikeRepository'
import { SupabaseCommentLikeRepository } from './supabase/repositories/SupabaseCommentLikeRepository'
import { SupabaseNotificationRepository } from './supabase/repositories/SupabaseNotificationRepository'
import { SupabaseGroupRepository } from './supabase/repositories/SupabaseGroupRepository'
import { SupabaseMessageRepository } from './supabase/repositories/SupabaseMessageRepository'
import { SupabaseDirectMessageRepository } from './supabase/repositories/SupabaseDirectMessageRepository'

import { GetFeedUseCase } from '../domain/usecases/questions/GetFeedUseCase'
import { GetHotFeedUseCase } from '../domain/usecases/questions/GetHotFeedUseCase'
import { GetAnsweredHistoryUseCase } from '../domain/usecases/questions/GetAnsweredHistoryUseCase'
import { PostQuestionUseCase } from '../domain/usecases/questions/PostQuestionUseCase'
import { EditQuestionUseCase } from '../domain/usecases/questions/EditQuestionUseCase'
import { DeleteQuestionUseCase } from '../domain/usecases/questions/DeleteQuestionUseCase'
import { SearchQuestionsUseCase } from '../domain/usecases/questions/SearchQuestionsUseCase'
import { GetQuestionStatsUseCase } from '../domain/usecases/questions/GetQuestionStatsUseCase'
import { AnswerQuestionUseCase } from '../domain/usecases/answers/AnswerQuestionUseCase'
import { GetMatchesUseCase } from '../domain/usecases/matches/GetMatchesUseCase'
import { GetCompareAnswersUseCase } from '../domain/usecases/matches/GetCompareAnswersUseCase'
import { GetProfileUseCase } from '../domain/usecases/users/GetProfileUseCase'
import { UpdateProfileUseCase } from '../domain/usecases/users/UpdateProfileUseCase'
import { SearchUsersUseCase } from '../domain/usecases/users/SearchUsersUseCase'
import { EnsureUserProfileUseCase } from '../domain/usecases/users/EnsureUserProfileUseCase'
import { GetCommentsUseCase } from '../domain/usecases/comments/GetCommentsUseCase'
import { PostCommentUseCase } from '../domain/usecases/comments/PostCommentUseCase'
import { DeleteCommentUseCase } from '../domain/usecases/comments/DeleteCommentUseCase'
import { ToggleQuestionLikeUseCase } from '../domain/usecases/likes/ToggleQuestionLikeUseCase'
import { ToggleCommentLikeUseCase } from '../domain/usecases/likes/ToggleCommentLikeUseCase'
import { GetNotificationsUseCase } from '../domain/usecases/notifications/GetNotificationsUseCase'
import { MarkAsReadUseCase } from '../domain/usecases/notifications/MarkAsReadUseCase'
import { SendFriendRequestUseCase } from '../domain/usecases/friendships/SendFriendRequestUseCase'
import { AcceptFriendRequestUseCase } from '../domain/usecases/friendships/AcceptFriendRequestUseCase'
import { DeleteFriendshipUseCase } from '../domain/usecases/friendships/DeleteFriendshipUseCase'
import { GetFriendsUseCase } from '../domain/usecases/friendships/GetFriendsUseCase'
import { GetGroupsUseCase } from '../domain/usecases/groups/GetGroupsUseCase'
import { GetGroupMessagesUseCase } from '../domain/usecases/messages/GetGroupMessagesUseCase'
import { SendGroupMessageUseCase } from '../domain/usecases/messages/SendGroupMessageUseCase'
import { GetDirectMessagesUseCase } from '../domain/usecases/directMessages/GetDirectMessagesUseCase'
import { SendDirectMessageUseCase } from '../domain/usecases/directMessages/SendDirectMessageUseCase'
import type { Env } from './env'

function shouldUseSupabase(env?: Env): env is Env & {
  SUPABASE_URL: string
  SUPABASE_SERVICE_ROLE_KEY: string
} {
  return Boolean(
    env?.REPOSITORY_MODE !== 'mock' &&
      env?.SUPABASE_URL &&
      env?.SUPABASE_SERVICE_ROLE_KEY
  )
}

export function createContainer(env?: Env) {
  const supabaseClient = shouldUseSupabase(env)
    ? new SupabaseRestClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY)
    : null

  const userRepo = supabaseClient
    ? new SupabaseUserRepository(supabaseClient)
    : new MockUserRepository()

  const friendshipRepo = supabaseClient
    ? new SupabaseFriendshipRepository(supabaseClient)
    : new MockFriendshipRepository()

  const commentRepo = supabaseClient
    ? new SupabaseCommentRepository(supabaseClient)
    : new MockCommentRepository()

  const questionLikeRepo = supabaseClient
    ? new SupabaseQuestionLikeRepository(supabaseClient)
    : new MockQuestionLikeRepository()

  const commentLikeRepo = supabaseClient
    ? new SupabaseCommentLikeRepository(supabaseClient)
    : new MockCommentLikeRepository()

  const notificationRepo = supabaseClient
    ? new SupabaseNotificationRepository(supabaseClient)
    : new MockNotificationRepository()

  const groupRepo = supabaseClient
    ? new SupabaseGroupRepository(supabaseClient)
    : new MockGroupRepository()

  const messageRepo = supabaseClient
    ? new SupabaseMessageRepository(supabaseClient)
    : new MockMessageRepository()

  const dmRepo = supabaseClient
    ? new SupabaseDirectMessageRepository(supabaseClient)
    : new MockDirectMessageRepository()

  const questionRepo = supabaseClient
    ? new SupabaseQuestionRepository(supabaseClient)
    : new MockQuestionRepository()

  const answerRepo = supabaseClient
    ? new SupabaseAnswerRepository(supabaseClient)
    : new MockAnswerRepository()

  const matchRepo = supabaseClient
    ? new SupabaseMatchRepository(supabaseClient)
    : new MockMatchRepository()

  return {
    getFeedUseCase: new GetFeedUseCase(questionRepo),
    getHotFeedUseCase: new GetHotFeedUseCase(questionRepo),
    getAnsweredHistoryUseCase: new GetAnsweredHistoryUseCase(questionRepo),
    postQuestionUseCase: new PostQuestionUseCase(questionRepo),
    editQuestionUseCase: new EditQuestionUseCase(questionRepo),
    deleteQuestionUseCase: new DeleteQuestionUseCase(questionRepo),
    searchQuestionsUseCase: new SearchQuestionsUseCase(questionRepo),
    getQuestionStatsUseCase: new GetQuestionStatsUseCase(questionRepo),
    answerQuestionUseCase: new AnswerQuestionUseCase(answerRepo, matchRepo, questionRepo),
    getMatchesUseCase: new GetMatchesUseCase(matchRepo),
    getCompareAnswersUseCase: new GetCompareAnswersUseCase(matchRepo),
    ensureUserProfileUseCase: new EnsureUserProfileUseCase(userRepo),
    getProfileUseCase: new GetProfileUseCase(userRepo),
    updateProfileUseCase: new UpdateProfileUseCase(userRepo),
    searchUsersUseCase: new SearchUsersUseCase(userRepo),
    getCommentsUseCase: new GetCommentsUseCase(commentRepo),
    postCommentUseCase: new PostCommentUseCase(commentRepo),
    deleteCommentUseCase: new DeleteCommentUseCase(commentRepo),
    toggleQuestionLikeUseCase: new ToggleQuestionLikeUseCase(questionLikeRepo),
    toggleCommentLikeUseCase: new ToggleCommentLikeUseCase(commentLikeRepo),
    getNotificationsUseCase: new GetNotificationsUseCase(notificationRepo),
    markAsReadUseCase: new MarkAsReadUseCase(notificationRepo),
    sendFriendRequestUseCase: new SendFriendRequestUseCase(friendshipRepo),
    acceptFriendRequestUseCase: new AcceptFriendRequestUseCase(friendshipRepo),
    deleteFriendshipUseCase: new DeleteFriendshipUseCase(friendshipRepo),
    getFriendsUseCase: new GetFriendsUseCase(friendshipRepo, userRepo),
    getGroupsUseCase: new GetGroupsUseCase(groupRepo),
    getGroupMessagesUseCase: new GetGroupMessagesUseCase(messageRepo, groupRepo),
    sendGroupMessageUseCase: new SendGroupMessageUseCase(messageRepo, groupRepo),
    getDirectMessagesUseCase: new GetDirectMessagesUseCase(dmRepo),
    sendDirectMessageUseCase: new SendDirectMessageUseCase(dmRepo),
  }
}
