#include <android/log.h>

extern "C" {

void __android_log_set_default_tag(const char*) {}

void __android_log_logd_logger(
        const struct __android_log_message*) {}

int __android_log_is_loggable(
        int, const char*, int) {
    return 1;
}

int32_t __android_log_set_minimum_priority(int32_t priority) {
    return priority;
}

int32_t __android_log_get_minimum_priority() {
    return 2;
}

void __android_log_set_logger(
        __android_logger_function) {}

void __android_log_set_aborter(
        __android_aborter_function) {}

void __android_log_write_log_message(
        struct __android_log_message*) {}

void __android_log_call_aborter(
        const char*) {}

}
