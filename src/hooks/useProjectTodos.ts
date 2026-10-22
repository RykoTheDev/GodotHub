import { projectTodosApi } from "../api/projectTodos";
import { useApiDataWithError } from "../lib/useApiData";
import { useCallback, useState } from "react";
import type { ProjectTodo } from "../types/projectTodo";
import { notifyTodosChanged } from "../lib/openTodos";

export function useProjectTodos(projectId: string) {
  const {
    data: todos,
    loaded,
    loading,
    error,
    refresh,
    setData: setTodos,
  } = useApiDataWithError(
    () => projectTodosApi.list(projectId),
    [projectId],
    [] as ProjectTodo[],
  );

  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [failedTodos, setFailedTodos] = useState<ProjectTodo[] | null>(null);

  const saveTodos = useCallback(
    async (
      nextTodos: ProjectTodo[],
      rememberFailure = true,
    ): Promise<boolean> => {
      setSaving(true);

      if (rememberFailure) {
        setSaveError(null);
      }

      try {
        const savedTodos = await projectTodosApi.save(projectId, nextTodos);

        setTodos(savedTodos);
        notifyTodosChanged();
        setFailedTodos(null);
        setSaveError(null);

        return true;
      } catch (error) {
        if (rememberFailure) {
          setFailedTodos(nextTodos);
          setSaveError(String(error));
        }

        return false;
      } finally {
        setSaving(false);
      }
    },
    [projectId, setTodos],
  );

  const sync = useCallback(
    async (scanComments: boolean) => {
      const result = await projectTodosApi.sync(projectId, scanComments);

      setTodos(result.todos);
      notifyTodosChanged();

      return result;
    },
    [projectId, setTodos],
  );

  const retrySave = useCallback(async (): Promise<boolean> => {
    if (!failedTodos) return false;

    return saveTodos(failedTodos);
  }, [failedTodos, saveTodos]);

  return {
    todos,
    loaded,
    loading,
    error,
    saving,
    saveError,
    refresh,
    saveTodos,
    retrySave,
    sync,
  };
}
