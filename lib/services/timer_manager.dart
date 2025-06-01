// 定義計時器管理類別
class TimerManager {
  // 時間設定（秒）
  final int focusTimeSeconds;
  final int breakTimeSeconds;

  // 目前狀態
  bool isRunning = false;
  bool isBreak = false;
  int remainingSeconds = 0;

  // 構造函數
  TimerManager({
    // 正式
    // this.focusTimeSeconds = 25 * 60,
    // this.breakTimeSeconds = 5 * 60,
    // 測試
    this.focusTimeSeconds = 6,
    this.breakTimeSeconds = 6,
  }) {
    reset();
  }

  // 重置計時器
  void reset() {
    isRunning = false;
    isBreak = false;
    resetRemainingTime();
  }

  // 重置剩餘時間
  void resetRemainingTime() {
    remainingSeconds = isBreak ? breakTimeSeconds : focusTimeSeconds;
  }

  // 開始計時
  void start() {
    isRunning = true;
    resetRemainingTime();
  }

  // 停止計時
  void stop() {
    isRunning = false;
  }

  // 切換到休息階段
  void switchToBreak() {
    isBreak = true;
    resetRemainingTime();
  }

  // 減少剩餘時間
  void decrementTime() {
    if (remainingSeconds > 0) {
      remainingSeconds--;
    }
  }

  // 檢查是否完成
  bool isCompleted() {
    return remainingSeconds <= 0;
  }

  // 獲取當前階段的總時間
  int getCurrentTotalTime() {
    return isBreak ? breakTimeSeconds : focusTimeSeconds;
  }

  // 獲取已經過的時間
  int getElapsedTime() {
    return getCurrentTotalTime() - remainingSeconds;
  }

  // 格式化時間顯示
  String formatTime() {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
