export type TodoStatus = "todo" | "paused" | "in_progress" | "done";

export type ProjectTodo = {
  id: string;
  title: string;
  status: TodoStatus;
  area: TodoArea;
  dueDate?: string;
  description?: string;
  createdAt: string;
};

export type TodoArea =
  | "programming"
  | "art"
  | "audio"
  | "design"
  | "narrative"
  | "other";

