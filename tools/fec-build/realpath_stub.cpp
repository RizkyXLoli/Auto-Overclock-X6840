#include "android-base/file.h"
#include <cerrno>
#include <cstdlib>
#include <string>
namespace android { namespace base {
bool Realpath(const std::string& path, std::string* result) { result->clear(); char* realpath_buf = nullptr; do { realpath_buf = realpath(path.c_str(), nullptr); } while (realpath_buf == nullptr && errno == EINTR); if (realpath_buf == nullptr) return false; result->assign(realpath_buf); free(realpath_buf); return true; }
} }
