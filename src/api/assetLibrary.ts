import { invoke } from '@tauri-apps/api/core'
import type {
  AssetLibraryCategory,
  AssetLibraryResponse,
  InstallAssetResult,
  ProjectTemplate,
} from '../types'

export const assetLibraryApi = {
  search: (
    filter: string | null,
    godotVersion: string | null,
    page: number,
    maxResults: number,
    assetType: string | null = null,
    categoryId: string | null = null,
    sort: string | null = null,
    reverse = false,
  ) =>
    invoke<AssetLibraryResponse>('search_asset_library', {
      filter,
      godotVersion,
      page,
      maxResults,
      assetType,
      categoryId,
      sort,
      reverse,
    }),
  installAsTemplate: (assetId: string) =>
    invoke<ProjectTemplate>('install_asset_as_template', { assetId }),
  install: (
    assetId: string,
    projectId: string | null,
    templateId: string | null,
  ) =>
    invoke<InstallAssetResult>('install_asset', {
      assetId,
      projectId,
      templateId,
    }),
  download: (assetId: string, destDir: string | null = null) =>
    invoke<string>('download_asset', { assetId, destDir }),
  searchStore: (
    filter: string | null,
    godotVersion: string | null,
    page: number,
    maxResults: number,
    sort: string | null = null,
  ) =>
    invoke<AssetLibraryResponse>('search_asset_store', {
      filter,
      godotVersion,
      page,
      maxResults,
      sort,
    }),
  downloadStoreAsset: (
    publisherSlug: string,
    assetSlug: string,
    title: string,
  ) =>
    invoke<string>('download_store_asset', {
      publisherSlug,
      assetSlug,
      title,
      destDir: null,
    }),
  installStoreAsset: (
    publisherSlug: string,
    assetSlug: string,
    title: string,
    projectId: string | null,
    templateId: string | null,
  ) =>
    invoke<InstallAssetResult>('install_store_asset', {
      publisherSlug,
      assetSlug,
      title,
      projectId,
      templateId,
    }),
  listCategories: () =>
    invoke<AssetLibraryCategory[]>('get_asset_library_categories'),
}
