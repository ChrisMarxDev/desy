import { createAgentRouter } from '@flue/runtime/routing';
import { Hono } from 'hono';

import { OrbitGenUiAgent } from './orbit_agent.ts';

/// Flutter connects directly to this native Flue route. It first POSTs a
/// user turn, then opens Flue's `view=updates&live=sse` stream from the
/// admission offset. No separate TypeScript proxy is required.
const app = new Hono();
app.route('/agents/orbit', createAgentRouter(OrbitGenUiAgent));

export default app;
