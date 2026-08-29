#include <stdint.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <linux/fs.h>
#include <unistd.h>

uint64_t get_block_device_size(int fd) {
    struct stat st{};
    if (fstat(fd, &st) != 0) return 0;

    if (S_ISREG(st.st_mode)) {
        return static_cast<uint64_t>(st.st_size);
    }

    if (S_ISBLK(st.st_mode)) {
        uint64_t size = 0;
        if (ioctl(fd, BLKGETSIZE64, &size) == 0) return size;
    }

    return 0;
}
