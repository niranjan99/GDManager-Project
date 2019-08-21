

import Foundation

public protocol ISettingsContainer {
 
    func DeleteAllSettings()
    func DeleteSetting(categoryName:String, settingName:String, filename:String)
    func DeleteCategory(categoryName:String, filename:String)
    func Save()
    func SetSettingValue<T>(originSetting:T, sourceType:String, value:String)
    func TryGetSettingValue<T>(category:String, name:String, value:T) -> Bool
    func FileName() -> String
    func Categories<T>() -> Dictionary<String, [T]>

    var fileName:String { get set }
    var categories:Dictionary<String, [ISetting]> { get set }
    var name : String { get set }
    
}
