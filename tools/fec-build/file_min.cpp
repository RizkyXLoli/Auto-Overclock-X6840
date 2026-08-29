#include "android-base/file.h"
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <cstdint>
#include <climits>
#include <string>
#include <string_view>
#include "android-base/unique_fd.h"
namespace android { namespace base {
bool ReadFdToString(borrowed_fd fd, std::string* content) { content->clear(); struct stat sb; if (fstat(fd.get(), &sb) != -1 && sb.st_size > 0 && sb.st_size <= SSIZE_MAX) { size_t fd_size = sb.st_size; if (fd_size > content->capacity()) content->reserve(fd_size); else if (fd_size < content->capacity() && content->capacity() - fd_size >= 64) { content->shrink_to_fit(); content->reserve(fd_size); } } char buf[4096]; ssize_t n; while ((n = TEMP_FAILURE_RETRY(read(fd.get(), &buf[0], sizeof(buf)))) > 0) content->append(buf, n); return n == 0; }
bool ReadFileToString(const std::string& path, std::string* content, bool follow_symlinks) { content->clear(); int flags = O_RDONLY | O_CLOEXEC | (follow_symlinks ? 0 : O_NOFOLLOW); unique_fd fd(TEMP_FAILURE_RETRY(open(path.c_str(), flags))); if (fd == -1) return false; return ReadFdToString(fd, content); }
bool WriteStringToFd(std::string_view content, borrowed_fd fd) { const char* p = content.data(); size_t left = content.size(); while (left > 0) { ssize_t n = TEMP_FAILURE_RETRY(write(fd.get(), p, left)); if (n == -1) return false; p += n; left -= n; } return true; }
bool ReadFully(borrowed_fd fd, void* data, size_t byte_count) { uint8_t* p = reinterpret_cast<uint8_t*>(data); size_t remaining = byte_count; while (remaining > 0) { ssize_t n = TEMP_FAILURE_RETRY(read(fd.get(), p, remaining)); if (n == 0) { errno = ENODATA; return false; } if (n == -1) return false; p += n; remaining -= n; } return true; }
bool WriteFully(borrowed_fd fd, const void* data, size_t byte_count) { const uint8_t* p = reinterpret_cast<const uint8_t*>(data); size_t remaining = byte_count; while (remaining > 0) { ssize_t n = TEMP_FAILURE_RETRY(write(fd.get(), p, remaining)); if (n == -1) return false; p += n; remaining -= n; } return true; }
} }
