#include <srl.hpp>

using namespace SRL::Types;

int main()
{
    SRL::Core::Initialize(HighColor::Colors::Black);
    SRL::Debug::Print(0, 1, "TGA Paletted Image Loading Bug Test");
    SRL::Debug::Print(0, 2, "Testing CRAM allocation bug");

    // First, let's manually set some allocation masks to trigger the bug
    SRL::Debug::Print(0, 4, "Setting up allocation masks...");
    
    // Mark some banks as used to create a pattern that triggers the bug
    // The bug occurs because of operator precedence in the condition check
    SRL::CRAM::SetBankUsedState(0, SRL::CRAM::TextureColorMode::Paletted256, true);
    SRL::CRAM::SetBankUsedState(1, SRL::CRAM::TextureColorMode::Paletted256, true);
    
    SRL::Debug::Print(0, 5, "Banks 0-1 marked as used");
    
    // Now test GetFreeBank for different modes
    SRL::Debug::Print(0, 7, "Testing GetFreeBank after marking banks:");
    
    int32_t bank16 = SRL::CRAM::GetFreeBank(SRL::CRAM::TextureColorMode::Paletted16);
    int32_t bank64 = SRL::CRAM::GetFreeBank(SRL::CRAM::TextureColorMode::Paletted64);
    int32_t bank128 = SRL::CRAM::GetFreeBank(SRL::CRAM::TextureColorMode::Paletted128);
    int32_t bank256 = SRL::CRAM::GetFreeBank(SRL::CRAM::TextureColorMode::Paletted256);
    
    SRL::Debug::Print(1, 9, "16 color: Bank %d (expect 32+)", bank16);
    SRL::Debug::Print(1, 10, "64 color: Bank %d (expect 8+)", bank64);
    SRL::Debug::Print(1, 11, "128 color: Bank %d (expect 4+)", bank128);
    SRL::Debug::Print(1, 12, "256 color: Bank %d (expect 2)", bank256);
    
    while (1)
    {
        SRL::Core::Synchronize();
    }

    return 0;
}