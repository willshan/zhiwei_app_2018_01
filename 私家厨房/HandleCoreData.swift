//
//  HandleCoreData.swift
//  私家厨房
//
//  Created by Will.Shan on 24/07/2017.
//  Copyright © 2017 待定. All rights reserved.
//

import UIKit
import CoreData

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
    
    //get random string
    class func RandomString()->String {
        let characters = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var ranStr = ""
        for _ in 0..<12 {
            
            let index = Int(arc4random_uniform(UInt32(characters.characters.count)))
            ranStr.append(characters[characters.index(characters.startIndex, offsetBy: index)])
            //ranStr.append(characters[characters.startIndex.advancedBy(index)])
        }
        return ranStr
    }
    
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
    }
	//Mark: - Clear data in coreData
    class func clearCoreData(_ userName : String) {
        //声明数据的请求
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
    }
    
    //Mark: - Insert data in coreData
    /*
     * 通过AppDelegate单利来获取管理的数据上下文对象，操作实际内容
     * 通过NSEntityDescription.insertNewObjectForEntityForName方法创建实体对象
     * 给实体对象赋值
     * 通过saveContext()保存实体对象
     */
    class func insertData(mealToServer : MealToServer?, meal : Meal?)-> Meal{
        //creat Meal
        let EntityName = "Meal"
        let mealToAdd = NSEntityDescription.insertNewObject(forEntityName: EntityName, into:context) as! Meal
        
        //对象赋值
        //从服务器下载
        let userName : String? = UserDefaults.standard.string(forKey: "user_name")
        if mealToServer != nil {
            mealToAdd.mealName = mealToServer!.mealName
            mealToAdd.spicy = Int64(mealToServer!.spicy)
            mealToAdd.date = mealToServer!.date
            mealToAdd.comment = mealToServer!.comment
            mealToAdd.mealType = mealToServer!.mealType!
            mealToAdd.cellSelected = mealToServer!.cellSelected
            mealToAdd.objectIDinServer = mealToServer!.objectId
            mealToAdd.userName = userName!
            mealToAdd.identifier = mealToServer?.identifier ?? RandomString()
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
            mealToAdd.objectIDinServer = meal!.objectIDinServer ?? "TBD"
            mealToAdd.userName = meal!.userName
            mealToAdd.identifier = meal?.identifier ?? RandomString()
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
        //保存
        saveContext()
		
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
    class func queryData(_ userName : String) -> [Meal] {
        
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
                print("+++++++++++++++++++++++++")
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        return meals
    }
    
    class func queryDataWithIdentifer(_ identifier : String) -> [Meal]? {
        
        //获取数据上下文对象
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
                print("+++++++++++++++++++++++++")
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
        return meals
    }
    
    
    class func queryDataWithIdentiferAndUser(_ userName : String, _ identifier : String) -> [Meal]? {
        
        //获取数据上下文对象
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
                print("+++++++++++++++++++++++++")
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
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
    class func updateData(_ meal : Meal){
        //声明数据的请求
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.fetchLimit = 10  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Meal"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate.init(format: "identifier = '\(meal.identifier)'", "")
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest) as! [Meal]
            
            //遍历查询的结果
            for info in fetchedObjects{
                //修改
                info.mealName = meal.mealName
                info.spicy = meal.spicy
                info.comment = meal.comment
                info.mealType = meal.mealType
                info.cellSelected = meal.cellSelected
                info.objectIDinServer = meal.objectIDinServer
                //info.invitationCode = meal.invitationCode
                
                //重新保存
                saveContext()
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
    }
    
    class func updateObjectIDinServer(identifier : String, objectIDinServer : String){
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
                //修改邮箱
                info.objectIDinServer = objectIDinServer
                //重新保存
                saveContext()
            }
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
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
    class func deleteData(_ identifier : String){
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
            
            //只删除一个
            let info = fetchedObjects.first!
            
            //删除对象
            context.delete(info)
            
            //重新保存
            saveContext()
            
            //遍历查询的结果
            /*for info in fetchedObjects{
                //删除对象
                context.delete(info)
                
                //重新保存
                saveContext()
            }*/
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
    }
}
