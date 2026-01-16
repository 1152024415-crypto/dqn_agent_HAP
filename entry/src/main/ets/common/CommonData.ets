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
interface ruleInterface {
  category: string;
  decision: string;
  description?: string;
}

interface dqnInterface {
  action: string;
  type: string
}

interface vlmInterface {
  scene_category: string;
  description: string;
};

export interface FormCardData {
  id: string;
  active_module: string;
  rule_engine?: ruleInterface;
  dqn?: dqnInterface;
  vlm?: vlmInterface;
  timestamp: number;
  favour: boolean;
}
