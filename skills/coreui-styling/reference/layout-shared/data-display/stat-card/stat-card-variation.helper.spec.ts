import { describe, expect, it } from 'vitest';
import { resolveVariationSentiment } from './stat-card-variation.helper';

describe('resolveVariationSentiment', () => {
  it('returns undefined when there is no variation to show', () => {
    expect(resolveVariationSentiment(undefined, 'up')).toBeUndefined();
  });

  it('treats an increase as positive when goodDirection is "up" (e.g. margem)', () => {
    expect(resolveVariationSentiment(12, 'up')).toBe('positive');
  });

  it('treats a decrease as negative when goodDirection is "up"', () => {
    expect(resolveVariationSentiment(-12, 'up')).toBe('negative');
  });

  it('inverts sentiment when goodDirection is "down" (e.g. desconto subindo é ruim)', () => {
    expect(resolveVariationSentiment(12, 'down')).toBe('negative');
    expect(resolveVariationSentiment(-12, 'down')).toBe('positive');
  });

  it('treats a zero variation as a non-decrease, matching the arrow-up threshold at >= 0', () => {
    expect(resolveVariationSentiment(0, 'up')).toBe('positive');
    expect(resolveVariationSentiment(0, 'down')).toBe('negative');
  });
});
