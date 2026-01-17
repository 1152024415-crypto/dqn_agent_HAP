/**
 * Form data class for widget
 */
export class FormData {
  formTime: string = '';
  cardList: FormCardData[] = [];
}

/**
 * Card data for widget
 */
export interface RuleEngineData {
  category: string;
  decision: string;
  description?: string;
}

export interface DQNData {
  action: string;
  type: string
}

export interface VLMData {
  scene_category: string;
  description: string;
};

export class FormCardData {
  id: string = '';
  active_module: string = '';
  rule_engine?: RuleEngineData;
  dqn?: DQNData;
  vlm?: VLMData;
  timestamp: number = 0;
  favour: boolean = false;
}
