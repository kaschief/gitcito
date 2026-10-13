/**
 * Whether a vertical scroller has content left below its visible part. The 1px slack absorbs the
 * fractional scrollTop a zoomed or HiDPI window reports at the very bottom, which would otherwise
 * keep the fade on forever.
 */
export function hasMoreBelow(scrollHeight: number, clientHeight: number, scrollTop: number): boolean {
  return scrollHeight - clientHeight - scrollTop > 1
}

/**
 * The scrollTop that puts an item in the middle of its scrolling box, never above the top. Offsets
 * are relative to the box (the box is the item's offsetParent).
 */
export function centeredScrollTop(itemTop: number, itemHeight: number, boxHeight: number): number {
  return Math.max(0, itemTop - (boxHeight - itemHeight) / 2)
}
