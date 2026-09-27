export type StatCardGoodDirection = 'up' | 'down';
export type StatCardVariationSentiment = 'positive' | 'negative';

/**
 * Maps a raw % change to a color sentiment based on what "good" means for the indicator
 * (e.g. margem subindo é bom, desconto subindo é ruim) — never the arithmetic sign alone.
 */
export function resolveVariationSentiment(variation: number | undefined, goodDirection: StatCardGoodDirection): StatCardVariationSentiment | undefined {
  if (variation === undefined) {
    return undefined;
  }
  const isIncrease: boolean = variation >= 0;
  const isGood: boolean = goodDirection === 'up' ? isIncrease : !isIncrease;
  return isGood ? 'positive' : 'negative';
}
