import type { AnchorHTMLAttributes, MouseEvent } from 'react'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import { openUrl } from '@tauri-apps/plugin-opener'

type AnchorProps = AnchorHTMLAttributes<HTMLAnchorElement>

function ExternalAnchor({ href, children, ...rest }: AnchorProps) {
  const onClick = (
    e: MouseEvent<HTMLAnchorElement>,
    url: string | undefined,
  ) => {
    if (!url || !/^https?:\/\//i.test(url)) return
    e.preventDefault()
    openUrl(url).catch(() => {})
  }
  return (
    <a
      href={href}
      {...rest}
      onClick={(e) => onClick(e, href)}
      target={/^https?:\/\//i.test(href ?? '') ? '_blank' : undefined}
      rel="noreferrer"
    >
      {children}
    </a>
  )
}

export function MarkdownBody({ children }: { children: string }) {
  return (
    <div className="markdown-body">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{ a: ExternalAnchor }}
      >
        {children}
      </ReactMarkdown>
    </div>
  )
}
