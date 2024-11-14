
//
//  Untitled.swift
//  WitSDK
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI
import CoreBluetooth
import WitSDKWatch



class AppContext: ObservableObject ,IBluetoothEventObserver, IBwt901bleRecordObserver{
    
    // 获得蓝牙管理器
    // Get bluetooth manager
    var bluetoothManager:WitBluetoothManager = WitBluetoothManager.instance 
    
    // 是否扫描设备中
    // Whether to scan the device
    @Published var enableScan = false
    
    // 蓝牙5.0传感器对象
    // Bluetooth 5.0 sensor object
    @Published var deviceList:[Bwt901ble] = [Bwt901ble]()
    
    // 要显示的设备数据
    // Device data to display
    @Published
    var deviceData:String = " device not connected"
    
    init(){
       
        // Current scan status
        self.enableScan = self.bluetoothManager.isScaning
      
        // start auto refresh thread
        startRefreshThread()
    }
    
    
    // MARK: Start scanning for devices
    @MainActor func scanDevices() {
        print("Start scanning for surrounding bluetooth devices  WatchKit Extension")
        
        // Remove all devices, here all devices are turned off and removed from the list
        removeAllDevice()
     
        // Registering a Bluetooth event observer
        self.bluetoothManager.registerEventObserver(observer: self)
     
        // Turn on bluetooth scanning
        self.bluetoothManager.startScan()
    }
    
   
    // MARK: This method is called if a Bluetooth Low Energy sensor is found
    func onFoundBle(bluetoothBLE: BluetoothBLE?) {
        if isNotFound(bluetoothBLE) {
            print("\(String(describing: bluetoothBLE?.peripheral.name)) found a bluetooth device \(bluetoothBLE?.mac ?? "")")
            self.deviceList.append(Bwt901ble(bluetoothBLE: bluetoothBLE))
        }
    }
    
    // 判断设备还未找到
    // Judging that the device has not been found
    func isNotFound(_ bluetoothBLE: BluetoothBLE?) -> Bool{
        for device in deviceList {
            if device.mac == bluetoothBLE?.mac {
                return false
            }
        }
        return true
    }
    
   
    // MARK: You will be notified here when the connection is successful
    func onConnected(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name))")
    }
    
  
    // MARK: Notifies you here when the connection fails
    func onConnectionFailed(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name)) ")
    }
    
    // MARK: You will be notified here when the connection is lost
    func onDisconnected(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name))")
    }
    
   
    // MARK: Stop scanning for devices
    func stopScan(){
     
        self.bluetoothManager.removeEventObserver(observer: self)
      
        self.bluetoothManager.stopScan()
    }
    
   
    // MARK: Turn on the device
    @MainActor func openDevice(bwt901ble: Bwt901ble?){
        print("MARK: Turn on the device")
        
        do {
            try bwt901ble?.openDevice()
         
            // Monitor data
            bwt901ble?.registerListenKeyUpdateObserver(obj: self)
        }
        catch{
            print("Failed to open device")
        }
    }
 
    // MARK: Remove all devices
    @MainActor func removeAllDevice(){
        print("device List \(deviceList)")
        for item in deviceList {
        
            closeDevice(bwt901ble: item)
        }
        print("remove all device")
        deviceList.removeAll()
    }
    
   
    // MARK: Turn off the device
    @MainActor func closeDevice(bwt901ble: Bwt901ble?){
        print("Turn off the device")
        bwt901ble?.closeDevice()
    }
    
    
    // MARK: You will be notified here when data from the sensor needs to be recorded
    func onRecord(_ bwt901ble: Bwt901ble) {
       
        let deviceData =  getDeviceDataToString(bwt901ble)
        
        // 打印到控制台,您也可以在这里把数据记录到您的文件中  Prints to the console, where you can also log the data to your file
        print(deviceData)
    }
    
   
    // MARK: Enable automatic execution thread
    func startRefreshThread(){
        // start a thread
        let thread = Thread(target: self,
                            selector: #selector(refreshView),
                            object: nil)
        thread.start()
    }
    
    
    // MARK: Refresh the view thread, which will refresh the sensor data displayed on the page here
    @objc func refreshView (){
       
        // Keep running this thread
        while true {
            // Refresh 5 times per second
            Thread.sleep(forTimeInterval: 1 / 5)
           
            // Temporarily save sensor data
            var tmpDeviceData:String = ""
          
            // Print the data of each device
            print("deviceList  \(deviceList)")
            for device in deviceList {
                if (device.isOpen){
              
                    // Get the data of the device and concatenate it into a string
                    let deviceData =  getDeviceDataToString(device)
                    tmpDeviceData = "\(tmpDeviceData)\r\n\(deviceData)"
                    print("tempDeviceData \(tmpDeviceData)")
                }
            }
            
          
            // Refresh ui
            DispatchQueue.main.async {
                self.deviceData = tmpDeviceData
            }
            
        }
    }
    
   
    // MARK: Get the data of the device and concatenate it into a string
    func getDeviceDataToString(_ device:Bwt901ble) -> String {
        var s = ""
        s  = "\(s)name:\(device.name ?? "")\r\n"
        s  = "\(s)mac:\(device.mac ?? "")\r\n"
        s  = "\(s)version:\(device.getDeviceData(WitSensorKey.VersionNumber) ?? "")\r\n"
        s  = "\(s)AX:\(device.getDeviceData(WitSensorKey.AccX) ?? "") g\r\n"
        s  = "\(s)AY:\(device.getDeviceData(WitSensorKey.AccY) ?? "") g\r\n"
        s  = "\(s)AZ:\(device.getDeviceData(WitSensorKey.AccZ) ?? "") g\r\n"
        s  = "\(s)GX:\(device.getDeviceData(WitSensorKey.GyroX) ?? "") °/s\r\n"
        s  = "\(s)GY:\(device.getDeviceData(WitSensorKey.GyroY) ?? "") °/s\r\n"
        s  = "\(s)GZ:\(device.getDeviceData(WitSensorKey.GyroZ) ?? "") °/s\r\n"
        s  = "\(s)AngX:\(device.getDeviceData(WitSensorKey.AngleX) ?? "") °\r\n"
        s  = "\(s)AngY:\(device.getDeviceData(WitSensorKey.AngleY) ?? "") °\r\n"
        s  = "\(s)AngZ:\(device.getDeviceData(WitSensorKey.AngleZ) ?? "") °\r\n"
        s  = "\(s)HX:\(device.getDeviceData(WitSensorKey.MagX) ?? "") μt\r\n"
        s  = "\(s)HY:\(device.getDeviceData(WitSensorKey.MagY) ?? "") μt\r\n"
        s  = "\(s)HZ:\(device.getDeviceData(WitSensorKey.MagZ) ?? "") μt\r\n"
        s  = "\(s)Electric:\(device.getDeviceData(WitSensorKey.ElectricQuantityPercentage) ?? "") %\r\n"
        s  = "\(s)Temp:\(device.getDeviceData(WitSensorKey.Temperature) ?? "") °C\r\n"
        return s
    }
    
    
    // MARK: Addition calibration
    func appliedCalibration(){
        for device in deviceList {
            
            do {
              
                // Unlock register
                try device.unlockReg()
              
                // Addition calibration
                try device.appliedCalibration()
               
                // save
                try device.saveReg()
                
            }catch{
                print(" Set failed")
            }
        }
    }
    
   
    // MARK: Start magnetic field calibration
    func startFieldCalibration(){
        for device in deviceList {
            do {
         
                // Unlock register
                try device.unlockReg()

                // Start magnetic field calibration
                try device.startFieldCalibration()

                // save
                try device.saveReg()
            }catch{
                print("Set failed")
            }
        }
    }
    

    // MARK: End magnetic field calibration
    func endFieldCalibration(){
        for device in deviceList {
            do {

                // Unlock register
                try device.unlockReg()
       
                // End magnetic field calibration
                try device.endFieldCalibration()

                // save
                try device.saveReg()
            }catch{
                print("Set failed")
            }
        }
    }
    

    // MARK: Read the 03 register
    func readReg03(){
        for device in deviceList {
            do {
                
                // Read the 03 register and wait for 200ms. If it is not read out, you can extend the reading time or read it several times
                try device.readRge([0xff ,0xaa, 0x27, 0x03, 0x00], 200, {
                    let reg03value = device.getDeviceData("03")
                  
                    // Output the result to the console
                    print("\(String(describing: device.mac)) reg03value: \(String(describing: reg03value))")
                })
            }catch{
                print(" Set failed")
            }
        }
    }
    
   
    // MARK: Set 50hz postback
    func setBackRate50hz(){
        for device in deviceList {
            do {
               
                // unlock register
                try device.unlockReg()
          
                // Set 50hz postback and wait 10ms
                try device.writeRge([0xff ,0xaa, 0x03, 0x08, 0x00], 10)
               
                // save
                try device.saveReg()
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
   
    // MARK: Set 10hz postback
    func setBackRate10hz(){
        for device in deviceList {
            do {
                
                // unlock register
                try device.unlockReg()
              
                // Set 10hz postback and wait 10ms
                try device.writeRge([0xff ,0xaa, 0x03, 0x06, 0x00], 100)
               
                // save
                try device.saveReg()
            }catch{
                print(" Set failed")
            }
        }
    }
}

// **********************************************************

// MARK: Home view start
// **********************************************************
struct HomeView: View {
    
    // App上下文
    // App the context
    @ObservedObject var viewModel:AppContext
    
  
    // MARK: Constructor
    init(_ viewModel:AppContext) {
       
        // View model
        self.viewModel = viewModel
    }
    
    
    // MARK: UI page
    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .center){
                HStack {
                    Text(" Control device")
                        .font(Font.system(size: 10))
                }
                HStack{
                    VStack{
                        Button("Acc cali") {
                            viewModel.appliedCalibration()
                        }.padding(5)
                        Button("Start mag cali"){
                            viewModel.startFieldCalibration()
                        }.padding(5)
                        Button("Stop mag cali"){
                            viewModel.endFieldCalibration()
                        }.padding(5)
                    }.font(Font.system(size: 10))
                    VStack{
                        Button("Read 03 reg"){
                            viewModel.readReg03()
                        }.padding(10)
                        Button("Set 50hz rate"){
                            viewModel.setBackRate50hz()
                        }.padding(10)
                        Button("Set 10hz rate"){
                            viewModel.setBackRate10hz()
                        }.padding(10)
                    }.font(Font.system(size: 10))
                }
                
                HStack {
                    Text("Device data")
                        .font(Font.system(size: 10))
                }
                
                List{
                    Text(self.viewModel.deviceData)
                        .fontWeight(.light)
                        .font(.body)
                }
                
            }
        }.navigationBarHidden(true)
    }
}


struct Home_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(AppContext())
    }
}


// **********************************************************

// MARK: Start with the view
// **********************************************************
struct ConnectView: View {
    
    
    // App the context
    @ObservedObject var viewModel:AppContext
    
    
    // MARK: Constructor
    init(_ viewModel:AppContext) {
        
        // View model
        self.viewModel = viewModel
    }
    
   
    // MARK: UI page
    var body: some View {
        ZStack(alignment: .leading) {
            VStack{
                Toggle(isOn: $viewModel.enableScan){
                    Text("Turn on scanning for surrounding devices")
                }.onChange(of: viewModel.enableScan) { _ , value in
                    if value {
                        viewModel.scanDevices()
                    }else{
                        viewModel.stopScan()
                    }
                }.padding(5)
              
                List{
                    ForEach (self.viewModel.deviceList){ device in
                        Bwt901bleView(device, viewModel)
                    }
           
                }
            }
        }
    }
}


struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView(AppContext())
    }
}

// **********************************************************

// MARK: View showing Bluetooth 5.0 sensor
// **********************************************************
struct Bwt901bleView: View{
    
   
    // bwt901ble instance
    @ObservedObject var device:Bwt901ble
    
    
    // App the context
    @ObservedObject var viewModel:AppContext
    
    
    // MARK: Constructor
    init(_ device:Bwt901ble,_ viewModel:AppContext){
        self.device = device
        self.viewModel = viewModel
    }
    
    
    // MARK: UI page
    var body: some View {
        VStack {
            Toggle(isOn: $device.isOpen) {
                VStack {
                    Text("\(device.name ?? "")")
                        .font(.headline)
                    Text("\(device.mac ?? "")")
                        .font(.subheadline)
                }
            }.onChange(of: device.isOpen) {_, value in
                if value {
                    viewModel.openDevice(bwt901ble: device)
                }else{
                    viewModel.closeDevice(bwt901ble: device)
                }
            }
            .padding(10)
        }
    }
}
