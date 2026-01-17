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

  // Helper methods to set nested data
  setRuleEngineData(data: RuleEngineData | undefined): void {
    if (data) {
      this.rule_engine = data;
    }
  }

  setDQNData(data: DQNData | undefined): void {
    if (data) {
      this.dqn = data;
    }
  }

  setVLMData(data: VLMData | undefined): void {
    if (data) {
      this.vlm = data;
    }
  }
}
