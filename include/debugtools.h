#include <iostream>
#include <random>
#include <chrono>
using namespace std;

enum class COLOR: int {RED=0,GREEN,ORANGE,BLUE,PURPLE,CYAN,YELLOW,COUNT};
constexpr std::string_view color_codes[] = {"\033[31m","\033[0;32m","\033[0;33m","\033[0;34m","\033[0;35m","\033[0;36m","\033[1;33m"};
void _DEBUG() { cout<<endl; }
template <typename T,typename... Args>
void _DEBUG(T first,Args... args) { cout<<first<<" ";_DEBUG(args...);}
template <typename... Args>
void DEBUG(COLOR color,string indicator,Args... args) {
#ifndef NO_COLOR
    auto idx = static_cast<int>(color);
    if (0 <= idx and idx < static_cast<int>(COLOR::COUNT))
        cout << color_codes[idx];
#endif
    cout << "[" << indicator << "] ";
    _DEBUG(args...);
#ifndef NO_COLOR
    cout << "\033[0m";
#endif
}