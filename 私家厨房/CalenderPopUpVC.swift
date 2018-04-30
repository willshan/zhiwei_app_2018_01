//
//  CalenderPopUpVC.swift
//  私家厨房
//
//  Created by Admin on 2018/4/7.
//  Copyright © 2018 待定. All rights reserved.
//

import UIKit
import CVCalendar

class CalenderPopUpVC: UIViewController {
    
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    
    var currentCalendar: Calendar!
    var delegate : DataTransferBackProtocol?
    var date : Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentCalendar = Calendar.init(identifier: .gregorian)
        self.title = CVDate(date: Date(), calendar: currentCalendar).globalDescription
        
        var todayButtonItem : UIBarButtonItem {
            return UIBarButtonItem(title: "今天", style: .plain, target: self, action: #selector(self.todayButtonTapped))
        }
        
        self.navigationItem.rightBarButtonItem = todayButtonItem
        
        //星期菜单栏代理
        self.menuView.menuViewDelegate = self
        
        //日历代理
        self.calendarView.calendarDelegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    //今天按钮点击
    @objc func todayButtonTapped() {
        let today = Date()
        self.calendarView.toggleViewWithDate(today)
    }
    
    //确定按钮点击
    @IBAction func confirmButtonTapped(_ sender: AnyObject) {
        
        let today = Date()
        let date = self.date ?? today
        delegate?.dateTransferBack!(date: date)
        
        //dismiss current VC
        if let owningNavigationController = self.navigationController{
            owningNavigationController.popViewController(animated: true)
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        menuView.commitMenuViewUpdate()
        calendarView.commitCalendarViewUpdate()
    }
}

extension CalenderPopUpVC: CVCalendarViewDelegate,CVCalendarMenuViewDelegate {
    //视图模式
    func presentationMode() -> CalendarMode {
        //使用月视图
        return .monthView
    }
    
    //每周的第一天
    func firstWeekday() -> Weekday {
        //从星期一开始
        return .monday
    }
    
    func presentedDateUpdated(_ date: CVDate) {
        //导航栏显示当前日历的年月
        self.title = date.globalDescription
    }
    
    //每个日期上面是否添加横线(连在一起就形成每行的分隔线)
    func topMarker(shouldDisplayOnDayView dayView: CVCalendarDayView) -> Bool {
        return true
    }
    
    //切换月的时候日历是否自动选择某一天（本月为今天，其它月为第一天）
    func shouldAutoSelectDayOnMonthChange() -> Bool {
        return false
    }
    
    //日期选择响应
    func didSelectDayView(_ dayView: CVCalendarDayView, animationDidFinish: Bool) {
        //获取日期
        let date = dayView.date.convertedDate()!
        self.date = date
/*
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd"
        let message = "当前选择的日期是：\(dformatter.string(from: date))"
        //将选择的日期弹出显示
        let alertController = UIAlertController(title: "", message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
 */
    }
}
