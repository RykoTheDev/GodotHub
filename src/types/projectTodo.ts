export type TodoStatus = "todo" | "paused" | "in_progress" | "done";

export type TodoLink = {
  path: string;
  line?: number;
};

export type TodoSource = {
  kind: "comment";
  tag: string;
  key: string;
};

export type TodoClosure = {
  kind: "comment_removed" | "commit";
  commit?: string;
  subject?: string;
  at: string;
};

export type ProjectTodo = {
  id: string;
  title: string;
  status: TodoStatus;
  area: TodoArea;
  dueDate?: string;
  description?: string;
  createdAt: string;
  number?: number;
  link?: TodoLink;
  source?: TodoSource;
  closedBy?: TodoClosure;
  priority?: TodoPriority;
  checklist?: TodoChecklistItem[];
  completedAt?: string;
};

export type TodoPriority = "low" | "medium" | "high";

export type TodoChecklistItem = {
  id: string;
  text: string;
  done: boolean;
};

export type OpenTodo = {
  projectId: string;
  projectName: string;
  todo: ProjectTodo;
};

export type TodoArea =
  | "programming"
  | "art"
  | "audio"
  | "design"
  | "narrative"
  | "other";

export type TodoSyncResult = {
  todos: ProjectTodo[];
  scanned: boolean;
  imported: number;
  closed: number;
  reopened: number;
  updated: number;
  closedByCommits: number;
  gitAvailable: boolean;
};

export type TodoCommit = {
  hash: string;
  shortHash: string;
  subject: string;
  author: string;
  date: string;
  closes: boolean;
};

export type TodoGitActivity = {
  isRepo: boolean;
  currentBranch: string | null;
  branches: string[];
  commits: TodoCommit[];
};
