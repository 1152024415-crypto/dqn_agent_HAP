/**
 * Form data class for widget
 */
export class FormData {
  formTime: string = '';
  cardList: FormCardData[] = [];
}

/**
 * Rule Engine data interface
 */
export interface RuleEngineData {
  category: string;
  decision: string;
  description?: string;
}

/**
 * DQN data interface
 */
export interface DQNData {
  action: string;
  type: 'recommend' | 'probe';
}

/**
 * VLM data interface
 */
export interface VLMData {
  scene_category: string;
  description: string;
}

/**
 * Card data for widget
 */
export class FormCardData {
  id: string = '';
  active_module: string = '';
  rule_engine?: RuleEngineData;
  dqn?: DQNData;
  vlm?: VLMData;
  timestamp: number = 0;
  favour: boolean = false;
}
