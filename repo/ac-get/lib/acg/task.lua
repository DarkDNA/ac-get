Task = {}

function Task:init(state, id, steps)
  self.id = id

  self.steps = steps or 0

  self.state = state

  self.state:call_hook("task_begin", id, steps)
end

function Task:update(detail, prog)
  self.state:call_hook("task_update", self.id, detail, prog, self.steps)
end

function Task:done(detail)
  self.state:call_hook("task_complete", self.id, detail or "")
end