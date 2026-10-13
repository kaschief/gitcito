import { useEffect, useRef, type RefObject } from 'react'
import { centeredScrollTop, hasMoreBelow } from '../lib/scrollList'

/**
 * For a list that scrolls in its own box (`.settings-scroll-list`). On mount the box scrolls so the
 * item matching `selected` sits in the middle; setting scrollTop directly keeps the page around it
 * from jumping, which scrollIntoView would do. While there is more below, the box carries
 * `data-more-below="true"`, which styles.css turns into a fade over the cut-off row.
 */
export function useScrollList<T extends HTMLElement>(selected: string): RefObject<T> {
  const ref = useRef<T>(null)
  useEffect(() => {
    const box = ref.current
    if (!box) return
    const chosen = box.querySelector<HTMLElement>(selected)
    if (chosen) box.scrollTop = centeredScrollTop(chosen.offsetTop, chosen.offsetHeight, box.clientHeight)
    const measure = (): void => {
      const more = String(hasMoreBelow(box.scrollHeight, box.clientHeight, box.scrollTop))
      if (box.dataset.moreBelow !== more) box.dataset.moreBelow = more
    }
    measure()
    // Content changes too: a custom theme added or deleted grows or shrinks the list.
    const resize = new ResizeObserver(measure)
    resize.observe(box)
    const content = new MutationObserver(measure)
    content.observe(box, { childList: true })
    box.addEventListener('scroll', measure, { passive: true })
    return () => {
      resize.disconnect()
      content.disconnect()
      box.removeEventListener('scroll', measure)
    }
  }, [selected])
  return ref
}
