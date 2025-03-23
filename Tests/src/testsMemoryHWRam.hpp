#include <srl.hpp>
#include <srl_log.hpp>
#include "srl_memory.hpp"

// https://github.com/siu/minunit
#include "minunit.h"

using namespace SRL;

extern "C"
{

    extern const uint8_t buffer_size;
    extern char buffer[];

    /**
     * @brief Set up routine for memory unit tests
     *
     * This function is called before each test in the memory test suite.
     * Currently, it does not perform any specific setup operations,
     * but provides a hook for future initialization requirements.
     */
    void memory_HWRam_test_setup(void)
    {
        // Placeholder for any necessary test initialization
        // Future implementations might include resetting memory state,
        // clearing buffers, or preparing test environments
    }

    /**
     * @brief Tear down routine for memory unit tests
     *
     * This function is called after each test in the memory test suite.
     * Currently, it does not perform any specific cleanup operations,
     * but provides a hook for future resource release or state reset.
     */
    void memory_HWRam_test_teardown(void)
    {
        // Placeholder for any necessary test cleanup
        // Future implementations might include freeing resources,
        // resetting global state, or clearing temporary data
    }

    /**
     * @brief Output header for test suite error reporting
     *
     * This function is called on the first test failure to print
     * a header indicating that memory unit test errors have occurred.
     * It increments a global error counter to ensure the header
     * is printed only once per test suite run.
     */
    void memory_HWRam_test_output_header(void)
    {
        // Print error header only on the first test failure
        if (!suite_error_counter++)
        {
            LogInfo("****UT_MEMORY_HWRAM_ERROR(S)****");
        }
    }

    /**
     * @brief Test memory allocation and deallocation
     *
     * Verifies that memory can be allocated and freed correctly.
     * Ensures that the allocated memory is not a null pointer and
     * that the free operation completes successfully.
     */
    MU_TEST(memory_HWRam_test_malloc_free)
    {
        size_t freeSpaceBefore = Memory::GetFreeSpace(Memory::Zone::HWRam);
        void *ptr = Memory::Malloc(100, Memory::Zone::HWRam);
        mu_assert(ptr != nullptr, "Memory allocation failed");

        Memory::Free(ptr);
        size_t freeSpaceAfter = Memory::GetFreeSpace(Memory::Zone::HWRam);
        mu_assert(freeSpaceAfter == freeSpaceBefore, "Memory free failed");
    }

    /**
     * @brief Test getting free memory space
     *
     * Verifies that the free memory space can be retrieved correctly.
     * Ensures that the free space is greater than zero.
     */
    MU_TEST(memory_HWRam_test_get_free_space)
    {
        size_t freeSpace = Memory::GetFreeSpace(Memory::Zone::HWRam);
        mu_assert(freeSpace > 0, "Failed to get free space");
    }

    /**
     * @brief Test getting used memory space
     *
     * Verifies that the used memory space can be retrieved correctly.
     * Ensures that the used space is greater than or equal to zero.
     */
    MU_TEST(memory_HWRam_test_get_used_space)
    {
        size_t usedSpace = Memory::GetUsedSpace(Memory::Zone::HWRam);
        mu_assert(usedSpace >= 0, "Failed to get used space");
    }

    /**
     * @brief Test getting memory zone size
     *
     * Verifies that the memory zone size can be retrieved correctly.
     * Ensures that the size is greater than zero.
     */
    MU_TEST(memory_HWRam_test_get_size)
    {
        size_t size = Memory::GetSize(Memory::Zone::HWRam);
        mu_assert(size > 0, "Failed to get memory zone size");
    }

    /**
     * @brief Test allocating zero bytes
     *
     * Verifies that allocating zero bytes returns a valid pointer.
     */
    MU_TEST(memory_HWRam_test_malloc_zero)
    {
        size_t freeSpaceBefore = Memory::GetFreeSpace(Memory::Zone::HWRam);
        void *ptr = Memory::Malloc(0, Memory::Zone::HWRam);
        mu_assert(ptr != nullptr, "Memory allocation of zero bytes failed");

        Memory::Free(ptr);
        size_t freeSpaceAfter = Memory::GetFreeSpace(Memory::Zone::HWRam);
        mu_assert(freeSpaceAfter == freeSpaceBefore, "Memory free failed");
    }

    /**
     * @brief Test freeing a null pointer
     *
     * Verifies that freeing a null pointer does not cause any issues.
     */
    MU_TEST(memory_HWRam_test_free_null)
    {
        size_t freeSpaceBefore = Memory::GetFreeSpace(Memory::Zone::HWRam);
        Memory::Free(nullptr);
        size_t freeSpaceAfter = Memory::GetFreeSpace(Memory::Zone::HWRam);
        mu_assert(freeSpaceAfter == freeSpaceBefore, "Freeing null pointer failed");
    }

    /**
     * @brief Test getting memory report for HWRam
     *
     * Verifies that the memory report can be retrieved correctly.
     */
    MU_TEST(memory_HWRam_test_get_report_hwram)
    {
        Memory::Report report = Memory::HighWorkRam::GetReport();
        mu_assert(report.TotalSize > 0, "Failed to get memory report for HWRam");
    }

    /**
     * @brief Test HighWorkRam memory allocation and deallocation
     *
     * Verifies that memory can be allocated and freed correctly in HighWorkRam.
     */
    MU_TEST(memory_HWRam_test_highworkram_malloc_free)
    {
        size_t freeSpaceBefore = Memory::HighWorkRam::GetFreeSpace();
        void *ptr = Memory::HighWorkRam::Malloc(100);
        mu_assert(ptr != nullptr, "HighWorkRam memory allocation failed");

        Memory::HighWorkRam::Free(ptr);
        size_t freeSpaceAfter = Memory::HighWorkRam::GetFreeSpace();
        mu_assert(freeSpaceAfter == freeSpaceBefore, "HighWorkRam memory free failed");
    }

    /**
     * @brief Test HighWorkRam memory reallocation
     *
     * Verifies that memory can be reallocated correctly in HighWorkRam.
     */
    MU_TEST(memory_HWRam_test_highworkram_realloc)
    {
        size_t freeSpaceBefore = Memory::HighWorkRam::GetFreeSpace();
        void *ptr = Memory::HighWorkRam::Malloc(100);
        mu_assert(ptr != nullptr, "HighWorkRam memory allocation failed");

        void *newPtr = Memory::HighWorkRam::Realloc(ptr, 200);
        mu_assert(newPtr != nullptr, "HighWorkRam memory reallocation failed");

        Memory::HighWorkRam::Free(newPtr);
        size_t freeSpaceAfter = Memory::HighWorkRam::GetFreeSpace();
        mu_assert(freeSpaceAfter == freeSpaceBefore, "HighWorkRam memory free failed");
    }

    /**
     * @brief Test getting HighWorkRam free memory space
     *
     * Verifies that the free memory space in HighWorkRam can be retrieved correctly.
     * Ensures that the free space is greater than zero.
     */
    MU_TEST(memory_HWRam_test_highworkram_get_free_space)
    {
        size_t freeSpace = Memory::HighWorkRam::GetFreeSpace();
        mu_assert(freeSpace > 0, "Failed to get HighWorkRam free space");
    }

    /**
     * @brief Test getting HighWorkRam used memory space
     *
     * Verifies that the used memory space in HighWorkRam can be retrieved correctly.
     * Ensures that the used space is greater than or equal to zero.
     */
    MU_TEST(memory_HWRam_test_highworkram_get_used_space)
    {
        size_t usedSpace = Memory::HighWorkRam::GetUsedSpace();
        mu_assert(usedSpace >= 0, "Failed to get HighWorkRam used space");
    }

    /**
     * @brief Test getting HighWorkRam memory zone size
     *
     * Verifies that the memory zone size in HighWorkRam can be retrieved correctly.
     * Ensures that the size is greater than zero.
     */
    MU_TEST(memory_HWRam_test_highworkram_get_size)
    {
        size_t size = Memory::HighWorkRam::GetSize();
        mu_assert(size > 0, "Failed to get HighWorkRam memory zone size");
    }

    /**
     * @brief Test new[] operator for HighWorkRam
     *
     * Verifies that the new[] operator allocates memory correctly in HighWorkRam.
     */
    MU_TEST(memory_HWRam_test_new_array_highworkram)
    {
        size_t freeSpaceBefore = Memory::GetFreeSpace(Memory::Zone::HWRam);
        void* ptr = new (SRL::Memory::Zone::HWRam) char[100];
        mu_assert(ptr != nullptr, "new[] operator in HighWorkRam failed");

        size_t freeSpaceAfterAlloc = Memory::GetFreeSpace(Memory::Zone::HWRam);
        mu_assert(freeSpaceAfterAlloc < freeSpaceBefore, "Memory allocation in HighWorkRam did not reduce free space");

        delete[] ptr;

        size_t freeSpaceAfterFree = Memory::GetFreeSpace(Memory::Zone::HWRam);
        mu_assert(freeSpaceAfterFree == freeSpaceBefore, "Memory free in HighWorkRam did not restore free space");
    }

    /**
     * @brief Test memory depletion for HighWorkRam
     *
     * Verifies behavior when memory is depleted in HighWorkRam.
     */
    MU_TEST(memory_HWRam_test_deplete_highworkram)
    {
        size_t freeSpace = Memory::GetFreeSpace(Memory::Zone::HWRam) / 2;
        void* ptr = nullptr;

        if (freeSpace > 0)
        {
            ptr = new (SRL::Memory::Zone::HWRam) char[freeSpace];

            snprintf(buffer, buffer_size, "Cannot allocate %d in HighWorkRam Memory", freeSpace);
            mu_assert(ptr != nullptr, buffer);
        }
        else
        {
            mu_assert(false, "HighWorkRam Memory is already full");
        }

        freeSpace = Memory::GetFreeSpace(Memory::Zone::HWRam);
        
        snprintf(buffer, buffer_size, "CMemory HighWorkRam is not full : %d remains", freeSpace);
        mu_assert(freeSpace == 0, buffer);

        void* ptr2 = new (SRL::Memory::Zone::HWRam) char[100];

        mu_assert(ptr2 == nullptr, "Memory depletion in HighWorkRam did not return nullptr");

        delete[] ptr2;
        delete[] ptr;

        // Validate that memory can be reallocated after depletion
        ptr = new (SRL::Memory::Zone::HWRam) char[100];
        mu_assert(ptr != nullptr, "Memory reallocation in HighWorkRam after depletion failed");

        delete[] ptr;
    }

    /**
     * @brief Test InRange function for HighWorkRam
     *
     * Verifies that the InRange function correctly identifies pointers within the HighWorkRam range.
     */
    MU_TEST(memory_HWRam_test_inrange_highworkram)
    {
        void* validPtr = (void*)0x06000000; // Valid address in HighWorkRam range
        void* invalidPtr = (void*)0x08000000; // Invalid address outside HighWorkRam range

        mu_assert(Memory::HighWorkRam::InRange(validPtr), "InRange failed for valid HighWorkRam address");
        mu_assert(!Memory::HighWorkRam::InRange(invalidPtr), "InRange failed for invalid HighWorkRam address");
    }

    /**
     * @brief Test reallocating to a larger size
     *
     * Verifies that reallocating to a larger size works correctly.
     */
    MU_TEST(memory_HWRam_test_realloc_larger)
    {
        void* ptr = new (SRL::Memory::Zone::HWRam) char[100];
        mu_assert(ptr != nullptr, "Initial allocation failed");

        ptr = SRL::Memory::HighWorkRam::Realloc(ptr, 200);
        mu_assert(ptr != nullptr, "Reallocation to larger size failed");

        delete[] ptr;
    }

    /**
     * @brief Test allocating and freeing very large blocks of memory
     *
     * Verifies that very large blocks of memory can be allocated and freed correctly.
     */
    MU_TEST(memory_HWRam_test_large_block)
    {
        size_t largeSize = SRL::Memory::HighWorkRam::GetFreeSpace() / 2;
        void* ptr = new (SRL::Memory::Zone::HWRam) char[largeSize];
        mu_assert(ptr != nullptr, "Large block allocation failed");

        delete[] ptr;
    }

    /**
     * @brief Test memory fragmentation and defragmentation
     *
     * Verifies that memory fragmentation and defragmentation are handled correctly.
     */
    MU_TEST(memory_HWRam_test_fragmentation)
    {
        void* ptr1 = new (SRL::Memory::Zone::HWRam) char[100];
        void* ptr2 = new (SRL::Memory::Zone::HWRam) char[200];
        void* ptr3 = new (SRL::Memory::Zone::HWRam) char[300];

        delete[] ptr2;

        void* ptr4 = new (SRL::Memory::Zone::HWRam) char[150];
        mu_assert(ptr4 != nullptr, "Fragmentation handling failed");

        delete[] ptr1;
        delete[] ptr3;
        delete[] ptr4;
    }

    /**
     * @brief Test handling of allocation failures
     *
     * Verifies that allocation failures are handled correctly.
     */
    MU_TEST(memory_HWRam_test_allocation_failure)
    {
        size_t freeSpace = SRL::Memory::HighWorkRam::GetFreeSpace();
        void* ptr = new (SRL::Memory::Zone::HWRam) char[freeSpace + 1];
        mu_assert(ptr == nullptr, "Allocation failure handling failed");
    }

    /**
     * @brief Test freeing unallocated or already freed memory
     *
     * Verifies that freeing unallocated or already freed memory is handled correctly.
     */
    MU_TEST(memory_HWRam_test_free_unallocated)
    {
        void* ptr = (void*)0x06000000; // Unallocated address
        SRL::Memory::Free(ptr); // Should not crash or cause issues

        ptr = new (SRL::Memory::Zone::HWRam) char[100];
        delete[] ptr;
        SRL::Memory::Free(ptr); // Should not crash or cause issues
    }

    /**
     * @brief Test stress testing with high memory usage and frequent allocations/deallocations
     *
     * Verifies that the system handles high memory usage and frequent allocations/deallocations correctly.
     */
    MU_TEST(memory_HWRam_test_stress)
    {
        for (int i = 0; i < 1000; ++i)
        {
            void* ptr = new (SRL::Memory::Zone::HWRam) char[100];
            mu_assert(ptr != nullptr, "Stress test allocation failed");

            delete[] ptr;
        }
    }

    /**
     * @brief Test boundary conditions for memory allocation
     *
     * Verifies that memory allocation works correctly at the boundary of memory zones.
     */
    MU_TEST(memory_HWRam_test_boundary_conditions)
    {
        size_t freeSpace = Memory::HighWorkRam::GetFreeSpace();
        void* ptr = new (SRL::Memory::Zone::HWRam) char[freeSpace - 1];
        mu_assert(ptr != nullptr, "Boundary condition allocation failed");

        delete[] ptr;
    }

    /**
     * @brief Test for memory leaks
     *
     * Verifies that there are no memory leaks by tracking allocated and freed memory.
     */
    MU_TEST(memory_HWRam_test_memory_leaks)
    {
        size_t freeSpaceBefore = Memory::HighWorkRam::GetFreeSpace();
        void* ptr = new (SRL::Memory::Zone::HWRam) char[100];
        mu_assert(ptr != nullptr, "Memory allocation failed");

        delete[] ptr;
        size_t freeSpaceAfter = Memory::HighWorkRam::GetFreeSpace();
        mu_assert(freeSpaceAfter == freeSpaceBefore, "Memory leak detected");
    }

    /**
     * @brief Memory test suite configuration and test case registration
     *
     * Configures the test suite with setup, teardown, and error reporting functions.
     * Registers individual test cases to be executed during the test run.
     */
    MU_TEST_SUITE(memory_HWRam_test_suite)
    {
        // Configure test suite with setup, teardown, and error reporting functions
        MU_SUITE_CONFIGURE_WITH_HEADER(&memory_HWRam_test_setup,
                                       &memory_HWRam_test_teardown,
                                       &memory_HWRam_test_output_header);

        // Register test cases to be executed
        MU_RUN_TEST(memory_HWRam_test_malloc_free);
        MU_RUN_TEST(memory_HWRam_test_get_free_space);
        MU_RUN_TEST(memory_HWRam_test_get_used_space);
        MU_RUN_TEST(memory_HWRam_test_get_size);
        MU_RUN_TEST(memory_HWRam_test_malloc_zero);
        MU_RUN_TEST(memory_HWRam_test_free_null);
        MU_RUN_TEST(memory_HWRam_test_get_report_hwram);
        MU_RUN_TEST(memory_HWRam_test_highworkram_malloc_free);
        MU_RUN_TEST(memory_HWRam_test_highworkram_realloc);
        MU_RUN_TEST(memory_HWRam_test_highworkram_get_free_space);
        MU_RUN_TEST(memory_HWRam_test_highworkram_get_used_space);
        MU_RUN_TEST(memory_HWRam_test_highworkram_get_size);
        MU_RUN_TEST(memory_HWRam_test_new_array_highworkram);
        MU_RUN_TEST(memory_HWRam_test_deplete_highworkram);
        MU_RUN_TEST(memory_HWRam_test_inrange_highworkram);
        MU_RUN_TEST(memory_HWRam_test_realloc_larger);
        MU_RUN_TEST(memory_HWRam_test_large_block);
        MU_RUN_TEST(memory_HWRam_test_fragmentation);
        MU_RUN_TEST(memory_HWRam_test_allocation_failure);
        MU_RUN_TEST(memory_HWRam_test_free_unallocated);
        MU_RUN_TEST(memory_HWRam_test_stress);
        MU_RUN_TEST(memory_HWRam_test_boundary_conditions);
        MU_RUN_TEST(memory_HWRam_test_memory_leaks);
    }
}
