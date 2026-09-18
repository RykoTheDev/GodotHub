import { projectTodosApi } from "../api/projectTodos";
import { useApiDataWithError } from "../lib/useApiData";
import { useCallback, useState } from "react";
import type { ProjectTodo } from "../types/projectTodo";

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
        await projectTodosApi.save(projectId, nextTodos);

        setTodos(nextTodos);
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
  };
}
