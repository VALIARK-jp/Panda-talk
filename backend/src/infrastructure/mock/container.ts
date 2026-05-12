import { MockUserRepository } from './MockUserRepository'
import { MockQuestionRepository } from './MockQuestionRepository'
import { MockAnswerRepository } from './MockAnswerRepository'
import { MockFriendshipRepository } from './MockFriendshipRepository'
import { MockMatchRepository } from './MockMatchRepository'
import { MockCommentRepository } from './MockCommentRepository'
import { MockQuestionLikeRepository } from './MockQuestionLikeRepository'
import { MockCommentLikeRepository } from './MockCommentLikeRepository'
import { MockNotificationRepository } from './MockNotificationRepository'
import { MockGroupRepository } from './MockGroupRepository'
import { MockMessageRepository } from './MockMessageRepository'
import { MockDirectMessageRepository } from './MockDirectMessageRepository'

import { GetFeedUseCase } from '../../domain/usecases/questions/GetFeedUseCase'
import { GetHotFeedUseCase } from '../../domain/usecases/questions/GetHotFeedUseCase'
import { PostQuestionUseCase } from '../../domain/usecases/questions/PostQuestionUseCase'
import { EditQuestionUseCase } from '../../domain/usecases/questions/EditQuestionUseCase'
import { DeleteQuestionUseCase } from '../../domain/usecases/questions/DeleteQuestionUseCase'
import { SearchQuestionsUseCase } from '../../domain/usecases/questions/SearchQuestionsUseCase'
import { GetQuestionStatsUseCase } from '../../domain/usecases/questions/GetQuestionStatsUseCase'
import { AnswerQuestionUseCase } from '../../domain/usecases/answers/AnswerQuestionUseCase'
import { GetMatchesUseCase } from '../../domain/usecases/matches/GetMatchesUseCase'
import { GetProfileUseCase } from '../../domain/usecases/users/GetProfileUseCase'
import { UpdateProfileUseCase } from '../../domain/usecases/users/UpdateProfileUseCase'
import { SearchUsersUseCase } from '../../domain/usecases/users/SearchUsersUseCase'
import { GetCommentsUseCase } from '../../domain/usecases/comments/GetCommentsUseCase'
import { PostCommentUseCase } from '../../domain/usecases/comments/PostCommentUseCase'
import { DeleteCommentUseCase } from '../../domain/usecases/comments/DeleteCommentUseCase'
import { ToggleQuestionLikeUseCase } from '../../domain/usecases/likes/ToggleQuestionLikeUseCase'
import { ToggleCommentLikeUseCase } from '../../domain/usecases/likes/ToggleCommentLikeUseCase'
import { GetNotificationsUseCase } from '../../domain/usecases/notifications/GetNotificationsUseCase'
import { MarkAsReadUseCase } from '../../domain/usecases/notifications/MarkAsReadUseCase'
import { SendFriendRequestUseCase } from '../../domain/usecases/friendships/SendFriendRequestUseCase'
import { AcceptFriendRequestUseCase } from '../../domain/usecases/friendships/AcceptFriendRequestUseCase'
import { DeleteFriendshipUseCase } from '../../domain/usecases/friendships/DeleteFriendshipUseCase'
import { GetFriendsUseCase } from '../../domain/usecases/friendships/GetFriendsUseCase'
import { GetGroupsUseCase } from '../../domain/usecases/groups/GetGroupsUseCase'
import { GetGroupMessagesUseCase } from '../../domain/usecases/messages/GetGroupMessagesUseCase'
import { SendGroupMessageUseCase } from '../../domain/usecases/messages/SendGroupMessageUseCase'
import { GetDirectMessagesUseCase } from '../../domain/usecases/directMessages/GetDirectMessagesUseCase'
import { SendDirectMessageUseCase } from '../../domain/usecases/directMessages/SendDirectMessageUseCase'

// Repositories
const userRepo = new MockUserRepository()
const questionRepo = new MockQuestionRepository()
const answerRepo = new MockAnswerRepository()
const friendshipRepo = new MockFriendshipRepository()
const matchRepo = new MockMatchRepository()
const commentRepo = new MockCommentRepository()
const questionLikeRepo = new MockQuestionLikeRepository()
const commentLikeRepo = new MockCommentLikeRepository()
const notificationRepo = new MockNotificationRepository()
const groupRepo = new MockGroupRepository()
const messageRepo = new MockMessageRepository()
const dmRepo = new MockDirectMessageRepository()

// Use Cases
export const getFeedUseCase = new GetFeedUseCase(questionRepo)
export const getHotFeedUseCase = new GetHotFeedUseCase(questionRepo)
export const postQuestionUseCase = new PostQuestionUseCase(questionRepo)
export const editQuestionUseCase = new EditQuestionUseCase(questionRepo)
export const deleteQuestionUseCase = new DeleteQuestionUseCase(questionRepo)
export const searchQuestionsUseCase = new SearchQuestionsUseCase(questionRepo)
export const getQuestionStatsUseCase = new GetQuestionStatsUseCase(questionRepo)
export const answerQuestionUseCase = new AnswerQuestionUseCase(answerRepo, matchRepo, questionRepo)
export const getMatchesUseCase = new GetMatchesUseCase(matchRepo)
export const getProfileUseCase = new GetProfileUseCase(userRepo)
export const updateProfileUseCase = new UpdateProfileUseCase(userRepo)
export const searchUsersUseCase = new SearchUsersUseCase(userRepo)
export const getCommentsUseCase = new GetCommentsUseCase(commentRepo)
export const postCommentUseCase = new PostCommentUseCase(commentRepo)
export const deleteCommentUseCase = new DeleteCommentUseCase(commentRepo)
export const toggleQuestionLikeUseCase = new ToggleQuestionLikeUseCase(questionLikeRepo)
export const toggleCommentLikeUseCase = new ToggleCommentLikeUseCase(commentLikeRepo)
export const getNotificationsUseCase = new GetNotificationsUseCase(notificationRepo)
export const markAsReadUseCase = new MarkAsReadUseCase(notificationRepo)
export const sendFriendRequestUseCase = new SendFriendRequestUseCase(friendshipRepo)
export const acceptFriendRequestUseCase = new AcceptFriendRequestUseCase(friendshipRepo)
export const deleteFriendshipUseCase = new DeleteFriendshipUseCase(friendshipRepo)
export const getFriendsUseCase = new GetFriendsUseCase(friendshipRepo, userRepo)
export const getGroupsUseCase = new GetGroupsUseCase(groupRepo)
export const getGroupMessagesUseCase = new GetGroupMessagesUseCase(messageRepo, groupRepo)
export const sendGroupMessageUseCase = new SendGroupMessageUseCase(messageRepo, groupRepo)
export const getDirectMessagesUseCase = new GetDirectMessagesUseCase(dmRepo)
export const sendDirectMessageUseCase = new SendDirectMessageUseCase(dmRepo)

