import { NgStyle } from '@angular/common';
import { Component, Input, computed } from '@angular/core';

@Component({
  selector: 'app-user-avatar',
  standalone: true,
  templateUrl: './user-avatar.html',
  imports: [NgStyle],
})
export class UserAvatar {
  /**
   * Deterministic input used to generate the gradient.
   * Example: user id, email hash, etc.
   */
  @Input({ required: true }) id!: string;

  /**
   * Size in pixels (default matches your screenshot)
   */
  @Input() size = 44;

  /**
   * Optional ring color class (Tailwind) for consistent style.
   * Example: "ring-white" or "ring-slate-200"
   */
  @Input() ringClass = 'ring-white';

  /**
   * Computed style for the gradient background based on the id.
   */
  gradientStyle = computed(() => {
    const { h1, h2, h3 } = gradientFromId(this.id);
    return {
      width: `${this.size}px`,
      height: `${this.size}px`,
      background: `linear-gradient(135deg,
        hsl(${h1} 85% 60%),
        hsl(${h2} 85% 58%),
        hsl(${h3} 85% 62%)
      )`,
    } as const;
  });
}

/** Create a deterministic gradient from a string */
function gradientFromId(id: string) {
  const seed = fnv1a32(id);

  // pick 3 hues spaced apart but still harmonious
  const h1 = seed % 360;
  const h2 = (h1 + 55 + ((seed >> 8) % 35)) % 360;
  const h3 = (h2 + 55 + ((seed >> 16) % 35)) % 360;

  return { h1, h2, h3 };
}

/** Fast stable hash (FNV-1a 32-bit) */
function fnv1a32(str: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}
