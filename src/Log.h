#include <godot.hpp>
#include <ref.hpp>
#include <utility_functions.hpp>
#include <project_settings.hpp>
#include <mutex.hpp>
#include <thread.hpp>
#include <time.hpp>

#ifndef LOG_H
#define LOG_H

using namespace godot;


class LogStream : public RefCounted{
    GDCLASS(LogStream, RefCounted);
    
public:
    enum LogLevel
    {
        DEFAULT,
        DEBUG,
        INFO,
        WARN,
        ERROR,
        FATAL,
    };

private:
    const String LOG_SETTING_LOC = String("addons/Log/");
    
    const String LOG_MESSAGE_FORMAT_KEY = LOG_SETTING_LOC + String("log_message_format");
    const String LOG_MESSAGE_FORMAT_DEFAULT_VALUE = "{log_name}/{level} [lb]{hour}:{minute}:{second}[rb] {message}";

    //const String LOG_LEVEL_KEY = LOG_SETTING_LOC + String("log_level");
    //const LogLevel LOG_LEVEL_DEFAULT_VALUE = LogLevel::INFO;

    const String USE_UTC_TIME_FORMAT_KEY = LOG_SETTING_LOC + String("use_utc_time_format");
    const bool USE_UTC_TIME_FORMAT_DEFAULT_VALUE = false;
    //Is this even needed??????
    const String BREAK_ON_ERROR_KEY = LOG_SETTING_LOC + String("break_on_error");
    const bool BREAK_ON_ERROR_DEFAULT_VALUE = true;

    const String PRINT_TREE_KEY = LOG_SETTING_LOC + String("print_tree_on_error");
    const bool PRINT_TREE_DEFAULT_VALUE = false;

    Dictionary log_names = {};
    LogLevel current_log_level;
    String log_name;
    Callable crash_behaviour;
    Signal logged_message;
    
    struct LogEntryData{
        String log_name;
        String message;
        LogLevel level;
        Array other_values_to_be_printed;
    };
    
    static bool first_time_init;
    static Ref<Mutex> log_mutex;
    static Ref<Thread> log_thread;
    static Vector<LogEntryData> log_buffer;

    void ensure_setting_exists(String setting_name, Variant default_value){
        if(!ProjectSettings::get_singleton()->has_setting(setting_name)){
            ProjectSettings::get_singleton()->set(setting_name, default_value);
            ProjectSettings::get_singleton()->set_initial_value(setting_name, default_value);
            ProjectSettings::get_singleton()->set_as_basic(setting_name, true);
            ProjectSettings::get_singleton()->save();
        }
    };
    inline void internal_log(String message, LogLevel level, Array other_values_to_be_printed=Array()){
        if (level == LogLevel::DEFAULT){
            error(message, other_values_to_be_printed);
        }else if (level >= current_log_level) {
            log_mutex->lock();
            LogEntryData data = {log_name, message, current_log_level, Array()};
            log_buffer.push_back(data);
            log_mutex->unlock();    
        }
    }

    void async_log(){
        log_mutex->lock();
        while(!log_buffer.is_empty()){
            LogEntryData data = log_buffer[0];
            log_buffer.remove_at(0);
            log_mutex->unlock();
            String format_string = ProjectSettings::get_singleton()->get(LOG_MESSAGE_FORMAT_KEY);
            String msg = format_string.format(get_format_data(data.message, data.level));
        }
    }

    Dictionary get_format_data(String msg, LogLevel level){
        bool use_utc = ProjectSettings::get_singleton()->get_setting(USE_UTC_TIME_FORMAT_KEY, USE_UTC_TIME_FORMAT_DEFAULT_VALUE);
        Dictionary now = Time::get_singleton()->get_datetime_dict_from_system(use_utc);
        
        now["second"] = format_entry(now, "second");
        now["minute"] = format_entry(now, "minute");
        now["hour"] = format_entry(now, "minute");
        now["day"] = format_entry(now, "day");
        now["month"] = format_entry(now, "month");
        now["year"] = format_entry(now, "year");

        now["log_name"] = log_name;
        now["message"] = msg;
        now["level"] = log_names[level];
        return now;
    }

    inline String format_entry(Dictionary time, String key){
        String value = String(time[key]);
        //reduce branching
        String value_0 = "0"+value;
        return value.length() > 1 ? value : value_0; 
    }

    String stringify_value(Variant value){
        switch (value.get_type())
        {
        case Variant::Type::NIL:
            return "";
        case Variant::Type::ARRAY:
            {
                String msg = "[";
                Array array = Array(value);
                for(int i = 0; i < array.size(); i++){
                    
                }
                return msg;
            }
        default:
            break;
        }
    }

    String stringify_object(){
        return "";
    }
public:
    
    LogStream(String log_name, LogLevel level=LogLevel::DEFAULT, Callable crash_behaviour=Callable()){
        log_names[LogLevel::DEBUG] = "Debug";
        log_names[LogLevel::INFO] = "Info";
        log_names[LogLevel::WARN] = "Warn";
        log_names[LogLevel::ERROR] = "Error";
        log_names[LogLevel::FATAL] = "Fatal";
        
        if(!first_time_init){
            first_time_init = true;
            ensure_setting_exists(LOG_MESSAGE_FORMAT_KEY, LOG_MESSAGE_FORMAT_DEFAULT_VALUE);
            ensure_setting_exists(USE_UTC_TIME_FORMAT_KEY, USE_UTC_TIME_FORMAT_DEFAULT_VALUE);
            ensure_setting_exists(BREAK_ON_ERROR_KEY, BREAK_ON_ERROR_DEFAULT_VALUE);
            ensure_setting_exists(PRINT_TREE_KEY, PRINT_TREE_DEFAULT_VALUE);
            
            log_mutex = Ref<Mutex>();
            log_thread = Ref<Thread>();
            log_buffer = Vector<LogEntryData>();
            log_thread->start(Callable(this, "async_log"));
        }

        this->log_name = log_name;
        this->current_log_level = level;
        this->crash_behaviour = crash_behaviour;
    }
    ~LogStream(){}
    
    inline void debug(String message, Array other_values_to_be_printed=Array()){internal_log(message, LogLevel::DEBUG, other_values_to_be_printed);}
    inline void info(String message, Array other_values_to_be_printed=Array()){internal_log(message, LogLevel::INFO, other_values_to_be_printed);}
    inline void warn(String message, Array other_values_to_be_printed=Array()){internal_log(message, LogLevel::WARN, other_values_to_be_printed);}
    inline void error(String message, Array other_values_to_be_printed=Array()){internal_log(message, LogLevel::ERROR, other_values_to_be_printed);}
    inline void err(String message, Array other_values_to_be_printed=Array()){error(message, other_values_to_be_printed);}
    inline void fatal(String message, Array other_values_to_be_printed=Array()){internal_log(message, LogLevel::FATAL, other_values_to_be_printed);}
    


    void set_level(LogLevel level){
        if (level != LogLevel::DEFAULT){
            this->current_log_level = level;
            info("Log level set to " + String(log_names[level]));
        }
        else{
            warn("Cannot set log level to DEFAULT");
        }
    }
    LogLevel get_level(){return this->current_log_level;}
    

protected:
    static void _bind_methods(){
        ClassDB::bind_method(D_METHOD("set_level", "current_log_level"), &LogStream::set_level);
        ClassDB::bind_method(D_METHOD("debug", "message"), &LogStream::debug);
        ClassDB::bind_method(D_METHOD("info", "message"), &LogStream::info);
        ClassDB::bind_method(D_METHOD("warn", "message"), &LogStream::warn);
        ClassDB::bind_method(D_METHOD("error", "message"), &LogStream::error);
        ClassDB::bind_method(D_METHOD("fatal", "message"), &LogStream::fatal);
    }
};
#endif