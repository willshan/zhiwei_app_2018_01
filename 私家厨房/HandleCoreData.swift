//
//  HandleCoreData.swift
//  私家厨房
//
//  Created by Will.Shan on 24/07/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData
import CloudKit


//User对象创建成功之后，接下来就是通过对象来使用CoreData了
class HandleCoreData: NSObject {
    //Mark: - Core data stack
    static var persistentContainer : NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores(completionHandler: {(storeDescription, error) in
            if let error = error as NSError?{
                fatalError("Unsolved error \(error), \(error.userInfo)")
            }
            
        })
        return container
    }()
	//define context
	static let context = persistentContainer.viewContext
    
    //save to context
    class func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            }
            catch {
                let nserror = error as NSError
                fatalError("Unsolved error \(nserror), \(nserror.userInfo)")
            }
        }
        print("++++++++++Complete saveContext+++++++++++++++")
    }
	//Mark: - Clear data in coreData
    class func clearCoreData(_ userName : String) {
        //声明数据的请求
        print("++++++++++clearCoreData+++++++++++++++")
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 30  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "userName = '\(userName)'")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            
            //遍历查询的结果
            for info in fetchedObjects{
                //删除
                context.delete(info)
            }
            print("共删除了\(fetchedObjects.count)")
            //重新保存
            saveContext()
            
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("++++++++++complete clearCoreData+++++++++++++++")
    }
    
    //Mark: - Insert data in coreData
    /*
     * 通过AppDelegate单利来获取管理的数据上下文对象，操作实际内容
     * 通过NSEntityDescription.insertNewObjectForEntityForName方法创建实体对象
     * 给实体对象赋值
     * 通过saveContext()保存实体对象
     */
    class func insertData(meal : Meal?, record : CKRecord?, database : String?)-> Meal{
        //creat Meal
        print("++++++++++insertData+++++++++++++++")
        let EntityName = "Meal"
        let mealToAdd = NSEntityDescription.insertNewObject(forEntityName: EntityName, into:context) as! Meal
        
        //对象赋值
        //从服务器下载
        if record != nil {
            let imageAsset = record!["image"] as! CKAsset
            let imageURL = imageAsset.fileURL
            let image = UIImage(contentsOfFile: imageURL.path)
            DataStore().setImage(image: image!, forKey: record!.recordID.recordName)
            
            mealToAdd.mealName = record!["mealName"] as! String
            mealToAdd.spicy = record!["spicy"] as! Int64
            mealToAdd.date = record!["mealCreatedAt"] as! NSDate
            mealToAdd.comment = record!["comment"] as? String
            mealToAdd.mealType = record!["mealType"] as! String
            if record!["cellSelected"] as! Int64 == Int64(0) {
                mealToAdd.cellSelected = false
            }
            else {
                mealToAdd.cellSelected = true
            }
            mealToAdd.userName = CKCurrentUserDefaultName
            mealToAdd.identifier = record!["mealIdentifier"] as! String
            mealToAdd.database = database ?? "Private"
            /*
            let userName : String? = UserDefaults.standard.string(forKey: "user_name")
            let invitationCode = InvitationCodeStorage().invitationCodeForKey(key: "invitationCode", userName: userName!)
            
            if invitationCode != nil {
                mealToAdd.invitationCode = invitationCode
            }
            else {
                mealToAdd.invitationCode = HandleCoreData.RandomString()
                InvitationCodeStorage().saveInvitaionCode(code: mealToAdd.invitationCode!, forKey: "invitationCode", userName: userName!)
            }*/
        }
        //本地插入
        if meal != nil {
            mealToAdd.mealName = meal!.mealName
            mealToAdd.spicy = meal!.spicy
            mealToAdd.date = meal!.date
            mealToAdd.comment = meal!.comment
            mealToAdd.mealType = meal!.mealType
            mealToAdd.cellSelected = meal!.cellSelected
            mealToAdd.userName = meal!.userName
            mealToAdd.identifier = meal?.identifier ?? NSUUID().uuidString
            mealToAdd.database = database ?? "Private"

        }
        
        //保存
        saveContext()
		print("++++++++++Complete insertData+++++++++++++++")
		return mealToAdd
    }
    
    
    ////Mark: - Query data in coreData
    /*
     * 利用NSFetchRequest方法来声明数据的请求，相当于查询语句
     * 利用NSEntityDescription.entityForName方法声明一个实体结构，相当于表格结构
     * 利用NSPredicate创建一个查询条件，并设置请求的查询条件
     * 通过context.fetch执行查询操作
     * 使用查询出来的数据
     */
    class func querySelectedMealsWithUserName(_ userName : String) -> [Meal] {
        
        print("++++++++++querySelectedMealsWithUserName+++++++++++++++")
        //获取数据上下文对象
        var meals = [Meal]()
        //声明数据的请求
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 100  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "userName = '\(userName)'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            
            //遍历查询的结果
            for info in fetchedObjects{
                if info.cellSelected == true {
                    meals.append(info)
                }
                else {
                    continue
                }
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("++++++++++Complete querySelectedMealsWithUserName+++++++++++++++")
        return meals
    }
    
    class func queryDataWithUserName(_ userName : String) -> [Meal] {
        print("+++++++++queryDataWithUserName++++++++++++++++")
        //获取数据上下文对象
        var meals = [Meal]()
        //声明数据的请求
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 100  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "userName = '\(userName)'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            
            //遍历查询的结果
            for info in fetchedObjects{
                meals.append(info)
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("+++++++++Completed QueryDataWithUserName++++++++++++++++")
        return meals
    }
    
    class func queryDataWithIdentifer(_ identifier : String) -> [Meal] {
        //获取数据上下文对象
        print("++++++++++queryDataWithIdentifer+++++++++++++++")
        var meals = [Meal]()
        //声明数据的请求
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 10  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity

        //设置查询条件
        let predicate = NSPredicate.init(format: "identifier = '\(identifier)'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            //遍历查询的结果
            for info in fetchedObjects{
                meals.append(info)
                
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("++++++++++Complete queryDataWithIdentifer+++++++++++++++")
        return meals
        
    }
    
    
    class func queryDataWithIdentiferAndUser(_ userName : String, _ identifier : String) -> [Meal]? {
        
        //获取数据上下文对象
        print("++++++++++queryDataWithIdentiferAndUser+++++++++++++++")
        var meals = [Meal]()
        //声明数据的请求
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 10  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        
        let predicate = NSPredicate.init(format: "identifier = '\(identifier)'", "userName = '\(userName)'")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            
            //遍历查询的结果
            for info in fetchedObjects{
                meals.append(info)
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("++++++++++Complete queryDataWithIdentiferAndUser+++++++++++++++")
        return meals
    }
    
    ////Mark: - Update data in coreData
    /*
     * 利用NSFetchRequest方法来声明数据的请求，相当于查询语句
     * 利用NSEntityDescription.entityForName方法声明一个实体结构，相当于表格结构
     * 利用NSPredicate创建一个查询条件，并设置请求的查询条件
     * 通过context.fetch执行查询操作
     * 将查询出来的数据进行修改,也即进行赋新值
     * 通过saveContext()保存修改后的实体对象
     */
    class func updateData(meal : Meal?, record : CKRecord?){
        //声明数据的请求
        print("++++++++++updateData+++++++++++++++")
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 10  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        if meal != nil {
            let predicate = NSPredicate.init(format: "identifier = '\(meal!.identifier)'", "")
            fetchRequest.predicate = predicate
            //查询操作
            do{
                let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
                //遍历查询的结果
                for info in fetchedObjects{
                    //修改
                    info.mealName = meal!.mealName
                    info.spicy = meal!.spicy
                    info.comment = meal!.comment
                    info.mealType = meal!.mealType
                    info.cellSelected = meal!.cellSelected
                    //重新保存
                    saveContext()
                }
            }catch {
                let nserror = error as NSError
                fatalError("查询错误： \(nserror), \(nserror.userInfo)")
            }
        }
        if record != nil {
            let predicate = NSPredicate.init(format: "identifier = '\(record!["mealIdentifier"] as! String)'", "")
            fetchRequest.predicate = predicate
            //查询操作
            do{
                let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
                //遍历查询的结果
                for mealToAdd in fetchedObjects{
                    //修改
                    let imageAsset = record!["image"] as! CKAsset
                    let imageURL = imageAsset.fileURL
                    let image = UIImage(contentsOfFile: imageURL.path)
                    DataStore().setImage(image: image!, forKey: record!.recordID.recordName)
                    
                    mealToAdd.mealName = record!["mealName"] as! String
                    mealToAdd.spicy = record!["spicy"] as! Int64
                    mealToAdd.date = record!["mealCreatedAt"] as! NSDate
                    mealToAdd.comment = record!["comment"] as? String
                    mealToAdd.mealType = record!["mealType"] as! String
//                    if record!["cellSelected"] as! Int64 == Int64(0) {
//                        mealToAdd.cellSelected = false
//                    }
//                    else {
//                        mealToAdd.cellSelected = true
//                    }
                    mealToAdd.userName = CKCurrentUserDefaultName
                    mealToAdd.identifier = record!["mealIdentifier"] as! String
                    //重新保存
                    saveContext()
                }
            }catch {
                let nserror = error as NSError
                fatalError("查询错误： \(nserror), \(nserror.userInfo)")
            }
        }
        print("++++++++++Complete updateData+++++++++++++++")
    }
    
    class func updateMealIdentifer(identifier : String, recordName : String){
        //声明数据的请求
        print("++++++++++updateMealIdentifer+++++++++++++++")
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 1  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "identifier = '\(identifier)'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            
            //遍历查询的结果
            for info in fetchedObjects{
                //修改identifer
                info.identifier = recordName
                //重新保存
                saveContext()
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("++++++++++Complete updateMealIdentifer+++++++++++++++")
    }
    
    class func updateMealSelectionStatus(identifier : String){
        //声明数据的请求
        print("++++++++++updateMealSelectionStatus+++++++++++++++")
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 1  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "identifier = '\(identifier)'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            
            //遍历查询的结果
            for meal in fetchedObjects{
                //修改identifer
                if meal.cellSelected == true {
                    meal.cellSelected = false
                    print("\(meal.identifier)")
                }
                else {
                    meal.cellSelected = true
                }
                //重新保存
                saveContext()
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("++++++++++Complete updateMealSelectionStatus+++++++++++++++")
    }
    
    
    ////Mark: - Delete data in coreData
    /*
     * 利用NSFetchRequest方法来声明数据的请求，相当于查询语句
     * 利用NSEntityDescription.entityForName方法声明一个实体结构，相当于表格结构
     * 利用NSPredicate创建一个查询条件，并设置请求的查询条件
     * 通过context.fetch执行查询操作
     * 通过context.delete删除查询出来的某一个对象
     * 通过saveContext()保存修改后的实体对象
     */
    class func deleteMealWithIdentifier(_ identifier : String){
        //声明数据的请求
        print("++++++++++deleteMealWithIdentifier+++++++++++++++")
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 10  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "identifier = '\(identifier)'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            if fetchedObjects.count > 0 {
                //只删除一个
                let info = fetchedObjects.first!
                print("deleted in core data successfully!")
                //删除对象
                context.delete(info)
                //重新保存
                saveContext()
            }
            else {
                return
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        print("++++++++++Complete deleteMealWithIdentifier+++++++++++++++")
    }
}
