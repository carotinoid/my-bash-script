////////////////// Header file /////////////////////
#include <bits/stdc++.h>

///////////////// Macro functions //////////////////
#define forr(i, n) for(ll i=1;i<=(n);i++)
#define fors(i, s, e) for(ll i=(s);i<=(e);i++)
#define fore(i, e, s) for(ll i=(e);i>=(s);i--)
#define getint(a) ll a; cin>>a;
#define getints(a, b) ll a,b; cin>>a>>b;
#define getll(a) ll a; cin>>a;
#define getlls(a, b) ll a,b; cin>>a>>b;
#define getstr(s) string s; cin >> s;
#define all(v) v.begin(), v.end()
#define endl '\n'
#define fi first
#define se second
#define pb push_back
#define set_decimal(n) cout<<fixed;cout.precision(n);
#define len(v) ll((v).size())
#define _ <<" "
#define next next_
using namespace std;
using ll = long long; using ld = long double;
using point = pair<ld,ld>;
const long long mod = 1'000'000'007;
// const long long mod = 998'244'353;
void setup();
void solve();
mt19937_64 rng(chrono::steady_clock::now().time_since_epoch().count());

//////////////////// User-defined Debug tools //////////////////////
#ifdef DEBUGTOOLS
#include"include/debugtools.h"
#else
void DEBUG() {}
template <typename T,typename... Args>
void DEBUG(T first, Args... args) {DEBUG(args...);} 
enum class COLOR: int {RED=0,GREEN,ORANGE,BLUE,PURPLE,CYAN,YELLOW,COUNT};
#endif

//////////////////// Useful tools //////////////////////
// #include <ext/pb_ds/assoc_container.hpp>
// #include <ext/pb_ds/tree_policy.hpp>
// using namespace __gnu_pbds;
// #define ordered_set tree<int, null_type, less<int>, rb_tree_tag,tree_order_statistics_node_update>

///////////////// Global variables ///////////////////


//////////////////// Solve /////////////////////////
void solve()
{  
    cout << "Hello, world!" << endl;
}

///////////////////// Main /////////////////////////
int main()
{
    cin.tie(0) -> sync_with_stdio(0); setup();
    // getint(n); forr(i, n)
    solve();
}
void setup() {return;}

