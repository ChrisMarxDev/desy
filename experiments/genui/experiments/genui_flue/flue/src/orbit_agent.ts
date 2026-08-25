'use agent';

import { defineTool, useModel, useTool } from '@flue/runtime';
import * as v from 'valibot';

/// A harmless fixture tool. Replace its implementation with an authenticated
/// Jira, GitHub, or calendar client; keep the capability server-side.
const listFocusItems = defineTool({
  name: 'list_focus_items',
  description: 'Returns the current high-priority work items for the workspace.',
  input: v.object({workspace: v.string()}),
  async run({data}) {
    return {
      output: {
        workspace: data.workspace,
        items: [
          {title: 'Review generated UI transport', state: 'working'},
          {title: 'Add read-only Jira connector', state: 'next'},
        ],
      },
    };
  },
});

/// The Flue-owned side of the experiment.
///
/// Flutter sends the current GenUI catalog prompt inside every user turn for
/// this intentionally small sample. A production agent should version/cache
/// the catalog per conversation instead of repeating it.
export function OrbitGenUiAgent() {
  useModel(process.env.FLUE_MODEL ?? 'anthropic/claude-haiku-4-5');
  useTool(listFocusItems);
  return `
You are the Orbit workspace agent. Use the tools available to you for factual
workspace data. Each user message supplies the Flutter GenUI catalog contract.
When ready to render, output only ordered A2UI JSON using that catalog. Do not
wrap A2UI in markdown, narrate it, or emit generated Dart/TypeScript code.
`;
}
