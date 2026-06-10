import { Hono } from 'hono'
import { cors } from 'hono/cors'
import questionsRouter from './presentation/routes/questions'
import answersRouter from './presentation/routes/answers'
import usersRouter from './presentation/routes/users'
import matchesRouter from './presentation/routes/matches'
import friendshipsRouter from './presentation/routes/friendships'
import commentsRouter from './presentation/routes/comments'
import likesRouter from './presentation/routes/likes'
import notificationsRouter from './presentation/routes/notifications'
import pushTokensRouter from './presentation/routes/push_tokens'
import groupsRouter from './presentation/routes/groups'
import directMessagesRouter from './presentation/routes/direct_messages'
import moderationRouter from './presentation/routes/moderation'

const app = new Hono()

app.use('*', cors())

// Routes
app.route('/questions', questionsRouter)
app.route('/answers', answersRouter)
app.route('/users', usersRouter)
app.route('/matches', matchesRouter)
app.route('/friendships', friendshipsRouter)

// Comment routes span /questions/:id/comments and /comments/:id
// so we register them at root
app.route('/', commentsRouter)

// Like routes span /questions/:id/likes and /comments/:id/likes
// so we register them at root
app.route('/', likesRouter)

app.route('/notifications', notificationsRouter)
app.route('/push-tokens', pushTokensRouter)
app.route('/groups', groupsRouter)
app.route('/direct_messages', directMessagesRouter)
app.route('/moderation', moderationRouter)

// Health check
app.get('/', (c) => c.json({ status: 'ok', service: 'panda-talk-backend' }))

export default app
