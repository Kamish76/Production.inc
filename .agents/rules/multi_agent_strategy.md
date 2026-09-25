# Multi-Agent Command Center Strategy

Whenever executing complex feature development or phased plans in this project:

1. **Role of Main Agent**: Act as the central orchestrator and command center. Do not execute all coding tasks sequentially yourself if they can be parallelized.
2. **Subagent Delegation**: Delegate isolated, non-conflicting tasks (e.g. independent UI components, specific service logic refactors) to up to 5 concurrent subagents to keep execution clean, fast, and efficient.
3. **Model Selection**: Always configure subagents to use the `flash` model (Gemini Flash 3.8 High) to balance speed and minimize token costs/limits.
4. **Integration & Version Control**: Require each subagent to create a separate git commit for their work, while the main agent oversees integration and handles any overarching tests or merge workflows.
