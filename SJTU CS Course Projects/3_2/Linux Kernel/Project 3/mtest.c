#include <linux/module.h>  
#include <linux/kernel.h>  
#include <linux/proc_fs.h>  
#include <linux/string.h>  
#include <linux/vmalloc.h>  
#include <linux/sched.h>
#include <linux/init.h>  
#include <linux/slab.h>  
#include <linux/mm.h>  
#include <linux/vmalloc.h>
#include <linux/highmem.h> 
#include <asm/uaccess.h> 
#include <linux/errno.h>
#include <linux/fs.h>
  
static void mtest_dump_vma_list(void)

{

    struct task_struct *task = current;                //get the task_struct of the current process

    struct mm_struct *mm = task->mm;

    struct vm_area_struct *vma;                //get the vma area of the current process

    int count = 0;     //the number of vma

    down_read(&mm->mmap_sem);

 

    for(vma = mm->mmap; vma; vma = vma->vm_next)

    {

        count++;

 

        printk("%d:  0x%lx 0x%lx ", count, vma->vm_start, vma->vm_end);

       

        if (vma->vm_flags & VM_READ)

            printk("r");

        else

            printk("-");

 

        if (vma->vm_flags & VM_WRITE)

            printk("w");

        else

            printk("-");

 

        if (vma->vm_flags & VM_WRITE)

            printk("x");

        else

            printk("-");

       

        printk("\n");

    }

 

    up_read(&mm->mmap_sem);

 

}

static struct page *

my_follow_page(struct vm_area_struct *vma, unsigned long addr)

{

    pgd_t *pgd;

    pmd_t *pmd;

    pud_t *pud;

    pte_t *pte;

 

    spinlock_t *ptl;

 

    struct page *page = NULL;

    struct mm_struct *mm = vma->vm_mm;

 

 

    pgd = pgd_offset(mm, addr);     //get pgd

    if (pgd_none(*pgd) || unlikely(pgd_bad(*pgd)))

        goto out;

 

    pud = pud_offset(pgd, addr);   //get pud

    if (pud_none(*pud) || unlikely(pud_bad(*pud)))

        goto out;

 

    pmd = pmd_offset(pud, addr);   //get pmd

    if (pmd_none(*pmd) || unlikely(pmd_bad(*pmd)))

        goto out;

 

    pte = pte_offset_map_lock(mm, pmd, addr, &ptl); //get pte

 

    if (!pte)

        goto out;

 

    if (!pte_present(*pte))   //pte not in memory

        goto unlock;

 

    page = pfn_to_page(pte_pfn(*pte));

 

    if (!page)

        goto unlock;

    get_page(page);

 

unlock:

    pte_unmap_unlock(pte, ptl);

   

out:

    return page;

 

}

 

static void mtest_find_page(unsigned long addr)

{

    struct vm_area_struct *vma;

    struct task_struct *task = current;

    struct mm_struct *mm = task->mm;

    unsigned long kernel_addr;

    struct page *page;

   

    down_read(&mm->mmap_sem);

    vma = find_vma(mm, addr);

    page = my_follow_page(vma, addr);

 

    if (!page)

    {

        printk("translation failed.\n");

        goto out;

    }

 

    kernel_addr = (unsigned long) page_address(page);

 

    kernel_addr += (addr & ~PAGE_MASK);

 

    printk("vma 0x%lx -> pma 0x%lx\n", addr, kernel_addr);

 

out:

    up_read(&mm->mmap_sem);

}

static void

mtest_write_val(unsigned long addr, unsigned long val)

{

    struct vm_area_struct *vma;

    struct task_struct *task = current;

    struct mm_struct *mm = task->mm;

    struct page *page;

    unsigned long kernel_addr;

 

    down_read(&mm->mmap_sem);

    vma = find_vma(mm, addr);

 

    //test if it is a legal vma

    if (vma && addr >= vma->vm_start && (addr + sizeof(val)) < vma->vm_end)

    {

        if (!(vma->vm_flags & VM_WRITE))   //test if we have rights to write

        {

            printk("cannot write to 0x%lx\n", addr);

            goto out;

        }

 

        page = my_follow_page(vma, addr);

        if (!page)

        {

            printk("page not found 0x%lx\n", addr);

            goto out;

        }

 

        kernel_addr = (unsigned long) page_address(page);

        kernel_addr += (addr &~ PAGE_MASK);

        printk("write 0x%lx to address 0x%lx\n", val, kernel_addr);

        *(unsigned long *)kernel_addr = val;

        put_page(page);

    }

    else

    {

        printk("no vma found for %lx\n", addr);

    }

    out:

        up_read(&mm->mmap_sem);

}

static ssize_t

mtest_write(struct file *file, const char __user *buffer, size_t count, loff_t *data)

{

    char buf[128];

    unsigned long val, val2;

 

    if (count > sizeof(buf))

        return -EINVAL;

 

    if (copy_from_user(buf, buffer, count))    //get the command from shell

        return -EINVAL;

 

    if (memcmp(buf, "listvma", 7) == 0)

        mtest_dump_vma_list();

    else if (memcmp(buf, "findpage", 8) == 0)

    {

        if (sscanf(buf+8, "%lx", &val) == 1)

            mtest_find_page(val);

    }

    else if (memcmp(buf, "writeval", 8) == 0)

    {

        if (sscanf(buf+8, "%lx %lx", &val, &val2) == 2)

        {

            mtest_write_val(val, val2);

        }

    }

    return count;

}

 

static struct

file_operations proc_mtest_operation = {

    write: mtest_write,

};

 

static int __init

mtest_init(void)

{

    proc_create("mtest", 0, NULL, &proc_mtest_operation);

    printk("Create mtest...\n");

    return 0;

}

 

static void __exit

mtest_exit(void)

{

    remove_proc_entry("mtest", NULL);

}

 

MODULE_LICENSE("GPL");

MODULE_DESCRIPTION("memory management task");

module_init(mtest_init);

module_exit(mtest_exit);
