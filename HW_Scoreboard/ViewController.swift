//
//  ViewController.swift
//  HW_Scoreboard
//
//  Created by 曹家瑋 on 2023/6/24.
//

import UIKit


// 使用UITextFieldDelegate協議，並在用戶完成輸入時，將 textField 的值複製到 yardageLabel 中
class ViewController: UIViewController, UITextFieldDelegate {


    // 顯示當前節數（footballQuarters）
    @IBOutlet weak var quarterLabel: UILabel!
    
    // 顯示時間（倒數計時）
    @IBOutlet weak var timerLabel: UILabel!
    
    // TapGesture （禁用或啟用）
    @IBOutlet var timerTapGesture: UITapGestureRecognizer!
    
    // 主、客隊計分 Label
    @IBOutlet weak var homeScoreLabel: UILabel!
    @IBOutlet weak var guestScoreLabel: UILabel!
    
    // 主、客隊名稱Label（nameColorCount）
    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var guestNameLabel: UILabel!
    
    // 主、客隊 Stepper
    @IBOutlet weak var homeScoreStepper: UIStepper!
    @IBOutlet weak var guestScoreStepper: UIStepper!
    
    // 檔數 SegmentedControl
    @IBOutlet weak var downSegmentedControl: UISegmentedControl!
    
    // 當前碼數 TextField
    @IBOutlet weak var yardsToGoTextField: UITextField!
    
    // 當前進攻狀態（檔數、碼數）
    @IBOutlet weak var downLabel: UILabel!
    @IBOutlet weak var yardageLabel: UILabel!
    
    // 開球位置的 Slider
    @IBOutlet weak var ballOnSlider: UISlider!
    // 開球位置的 Label
    @IBOutlet weak var ballOnLabel: UILabel!
    
    
    // 起始時間（單節15分鐘轉換為秒數）
    var singleQuarterTimeSeconds = 15 * 60
    
    // 創建一個倒數計時器的實例
    var timer: Timer!
    
    
    // 節數
    let footballQuarters: [String] = ["1st Quarter", "2nd Quarter", "3rd Quarter", "4th Quarter"]
    // 當前的節數
    var countQuarterIndex = 0
    
    // 追蹤主、客隊分數
    var homeScoreCount = 0
    var guestScoreCount = 0
    
    // 追蹤主客隊名稱顏色
    var nameColorCount = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始時將時間轉為分秒格式
        timerLabel.text = timeString(time: TimeInterval(singleQuarterTimeSeconds))
        
        // 初始化節數
        quarterLabel.text = "1st Quarter"
        
        // 初始化檔數提示狀態
        downLabel.text = downSegmentedControl.titleForSegment(at: downSegmentedControl.selectedSegmentIndex)
        
        // 設置Ball on slider 的 thumb tint 圖片
        let originalImage = UIImage(named: "TintImage_small")
        ballOnSlider.setThumbImage(originalImage, for: .normal)
        
        // ballOnLabel 的初始
        let yards = Int(ballOnSlider.value)
        ballOnLabel.text = "Ball On：\(yards) yards"
        
        // 設置 yardsToGoTextField 的委派為 ViewController
        yardsToGoTextField.delegate = self
        
        // 呼叫 resignFirstResponder() 方法來隱藏鍵盤
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

    }
    

    // 總時間開始暫停按鈕
    @IBAction func fulltimeTapped(_ sender: UITapGestureRecognizer) {
        
        // 如果時間不為nil，開始倒數
        if timer == nil {
            // 創建了一個定期觸發的計時器
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
            
            // 開始計時時，變為紅色
            timerLabel.textColor = UIColor.red
        }
        else {
            // 如果 timer 不為 nil，則停止計時
            timer.invalidate()                  // 停止計時器的觸發
            timer = nil                         // 將計時器設定為 nil，表示計時暫停
            
            // 停止計時時，變回白色
            timerLabel.textColor = UIColor.white
        }
        
    }
    
    
    // 下一節（會重置單節時間）
    @IBAction func nextQuarterSwipe(_ sender: UISwipeGestureRecognizer) {
        
        // 檢查是否可以進入下一節
        if countQuarterIndex < footballQuarters.count - 1 {
            countQuarterIndex += 1
            quarterLabel.text = footballQuarters[countQuarterIndex]
            // 重置時間
            restQuarterTime()
        }
    }
    
    // 前一節（會重置單節時間）
    @IBAction func previousQuarterSwipe(_ sender: UISwipeGestureRecognizer) {
        
        // 檢查是否可以返回前一節
        if countQuarterIndex > 0 {
            countQuarterIndex -= 1
            quarterLabel.text = footballQuarters[countQuarterIndex]
            // 重置時間
            restQuarterTime()
        }
    }
    
    
    // 主隊加減分
    @IBAction func homeScoreStepperValueChanged(_ sender: UIStepper) {
        
        // 更新主隊的分數並顯示到Label
        homeScoreCount = Int(sender.value)
        homeScoreLabel.text = String(format: "%02d", homeScoreCount)
    }
    
    // 客隊加減分
    @IBAction func guestScoreStepperValueChanged(_ sender: UIStepper) {
        
        // 更新客隊的分數並顯示到Label
        guestScoreCount = Int(sender.value)
        guestScoreLabel.text = String(format: "%02d", guestScoreCount)
    }
    
    
    // 互換主客隊名的顏色（白、紅）
    @IBAction func changeSideColorButtonTapped(_ sender: UIButton) {
        
        // 將 nameColorCount 加 1（從而達到切換標籤顏色的目的）
        nameColorCount += 1
        
        // 偶數（Home紅色、Guest白色）、單數（Home白色、Guest紅色）
        if nameColorCount % 2 == 0 {
            homeNameLabel.textColor = UIColor.red
            guestNameLabel.textColor = UIColor.white
        }
        else {
            homeNameLabel.textColor = UIColor.white
            guestNameLabel.textColor = UIColor.red
        }
    }
    
    
    // 當前檔數（Down）
    @IBAction func downSegmentedControlChanged(_ sender: UISegmentedControl) {
        let selectedDown = sender.titleForSegment(at: sender.selectedSegmentIndex)
        
        let downText = "\(selectedDown!)"
        downLabel.text = downText
    }
    
    
    // 開球位置 Slider
    @IBAction func ballOnSliderValueChanged(_ sender: UISlider) {
        let yards = Int(sender.value)
        ballOnLabel.text = "Ball On：\(yards) yards"
    }
    
    
    // 重置按鈕
    @IBAction func restAllButtonTapped(_ sender: UIButton) {
        // 重置單節時間
        restQuarterTime()
        
        // 重置節數
        countQuarterIndex = 0
        quarterLabel.text = footballQuarters[countQuarterIndex]

        // 重置主、客隊分數
        homeScoreCount = 0
        guestScoreCount = 0
        homeScoreStepper.value = 0
        guestScoreStepper.value = 0
        homeScoreLabel.text = "00"
        guestScoreLabel.text = "00"
        
        // 重置Home、Guest名稱顏色
        nameColorCount = 0
        homeNameLabel.textColor = UIColor.red
        guestNameLabel.textColor = UIColor.white
        
        // 重置檔數提示狀態
        downSegmentedControl.selectedSegmentIndex = 0
        downLabel.text = downSegmentedControl.titleForSegment(at: downSegmentedControl.selectedSegmentIndex)
        
        // 重置開球位置 Slider
        ballOnSlider.value = 0
        let yards = Int(ballOnSlider.value)
        ballOnLabel.text = "Ball On：\(yards) yards"
        
        // 重置碼數 TextField
        yardsToGoTextField.text = nil
        // 重置開球位置 Label
        yardageLabel.text = "0 yards"
    }
    
    
    // 更新timerLabel
    @objc func updateTimer() {
        singleQuarterTimeSeconds -= 1                                                     // 每次減去一秒
        timerLabel.text = timeString(time: TimeInterval(singleQuarterTimeSeconds))        // 將新的時間值傳遞給 timeString 方法進行字串化後，更新 Label
        
        // 如果時間為0，則停止計時器（確保計時器已經停止並且可以重新啟動）
        if singleQuarterTimeSeconds == 0 {
            timer.invalidate()                                    // 無效化
            timer = nil                                           // 當點擊"暫停"時，則會停止計時並將 timer 設為 nil。
            
            // 時間歸0，TapGesture 禁用（避免還可以點出現負數）
            timerTapGesture.isEnabled = false
            // 歸零時，文字變白色
            timerLabel.textColor = UIColor.white
        }
        
    }
    
    
    // 將時間轉換為分鐘和秒的格式
    func timeString(time: TimeInterval) -> String {
        
        let minutes = Int(time) / 60                               // 分鐘
        let seconds = Int(time) % 60                               // 秒
        
        // 將分鐘和秒數格式化為兩位數的字串
        return String(format: "%02i:%02i", minutes, seconds)
    }
    
    
    // 重置單節時間
    func restQuarterTime() {
        
        // 如果 timer 不為 nil，表示目前正在計時，可以停止計時
        if timer != nil {
            timer.invalidate()
            timer = nil
            // 並且會變白色
            timerLabel.textColor = UIColor.white
        }
        
        // 重新設定時間 15分鐘、更新時間顯示
        singleQuarterTimeSeconds = 15 * 60
        timerLabel.text = timeString(time: TimeInterval(singleQuarterTimeSeconds))
        timerTapGesture.isEnabled = true
    }
    
    
    // 文字輸入更新 yardageLabel
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {

        // 檢查是否為 yardsToGoTextField，以確保只處理TextField的編輯事件
        if textField == yardsToGoTextField {
            
            // 當 UITextField 是空的時候，yardageLabel 會顯示 "0 yards"
            if textField.text?.isEmpty == true {
                yardageLabel.text = "0 yards"
            }
            else {
                // 當 UITextField 不是空的時候，將文本框的內容與 yards 結合後更新 yardageLabel
                yardageLabel.text = textField.text! + " yards"
            }
            
        }
        
        return true
    }
    
    
    // UITextFieldDelegate 方法：限制只能輸入範圍在 1 到 100 之間的數字（測試）
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // 檢查是否為 yardsToGoTextField，以確保只限制該文本框的輸入範圍
        if textField == yardsToGoTextField {
            
            // 取得輸入後的完整字串
            let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            
            // 檢查是否為合法的數字
            if let number = Int(newText) {
                
                // 檢查數字範圍是否在 1 到 100 之間
                if number >= 1 && number <= 100 {
                    // 允許輸入
                    return true
                }
                
            }
            // 不允許輸入
            return false
        }
        
        return true // 其他 textField 不進行限制
    }
    
    
    // 呼叫 resignFirstResponder() 方法來隱藏鍵盤。
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    
}


