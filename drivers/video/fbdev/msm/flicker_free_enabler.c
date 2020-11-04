#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <asm/uaccess.h>

#include "flicker_free.h"

#define PROC_NAME "flicker_free"

#define PROC_DIR_NAME "flicker_free"
#define MIN_BRIGHTNESS "min_brightness"

struct proc_dir_entry *root_entry;

struct proc_dir_entry *enabled, *minbright;

static int show_ff_enabled( struct seq_file *seq, void *v)
{
        seq_printf(seq, "%d\n", (if_flicker_free_enabled()?1:0));
        return 0;
}

static int my_open_ff_enabled(struct inode *inode, struct file *file)
{
    return single_open(file, show_ff_enabled, NULL);
}

static ssize_t my_write_procmem( struct file *file, const char __user *buffer,
                            size_t count, loff_t *pos)
{
    int value;
    value = 0;
    get_user(value,buffer);
    switch (value)
    {
    case '0':
        set_flicker_free(false);
        break;
    
    default:
        set_flicker_free(true);
        break;
    }
    return count;
}

static ssize_t my_write_procbright( struct file *file, const char __user *buffer,
                            size_t count, loff_t *pos)
{
    int value = 0;
    char *tmp = kzalloc((count+1), GFP_KERNEL);  
    if(!tmp)  
        return -ENOMEM;  
    if(copy_from_user(tmp, buffer, count))  
    {  
        kfree(tmp);  
        return EFAULT;  
    }  
    if(!kstrtoint(tmp,10,&value))
    {
        set_elvss_off_threshold(value);
    }else{
        kfree(tmp);
        return EFAULT;
    }
    kfree(tmp);
    return count;
}

static int show_procbright( struct seq_file *seq, void *v)
{
    seq_printf(seq, "%d\n", get_elvss_off_threshold());
    return 0;
}

static int my_open_procbright(struct inode *inode, struct file *file)
{
    return single_open(file, show_procbright, NULL);
}

static const struct file_operations proc_file_fops_enable = {
    .owner = THIS_MODULE,
    .open = my_open_ff_enabled,
    .read = seq_read,
    .write = my_write_procmem,
    .llseek = seq_lseek,
    .release = single_release,
};

static const struct file_operations proc_file_fops_minbright = {
    .owner = THIS_MODULE,
    .open = my_open_procbright,
    .read = seq_read,
    .write = my_write_procbright,
    .llseek = seq_lseek,
    .release = single_release,
};

static int __init init( void )
{
    root_entry = proc_mkdir(PROC_DIR_NAME, NULL);
    enabled = proc_create(PROC_NAME, 0x0666, root_entry, &proc_file_fops_enable);
    minbright = proc_create(MIN_BRIGHTNESS, 0x0666, root_entry, &proc_file_fops_minbright);
    if (!enabled && !minbright) {
        return ( -EINVAL );
    }

    return 0;
}

static void __exit cleanup( void )
{
        remove_proc_entry(PROC_NAME, root_entry);
        remove_proc_entry(MIN_BRIGHTNESS, root_entry);
}

module_init( init );
module_exit( cleanup );

