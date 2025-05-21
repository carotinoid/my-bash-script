
template <typename T, T(*op)(T, T), T I>
struct Segtree {

    // Variables
    T *arr;
    int arr_size, seg_size;
    T *seg;

    // Constructor
    Segtree(int s, T *a = NULL) {
        arr = a; arr_size = s;
        seg_size = arr_size * 4 + 1;
        seg = new T[seg_size];
        build(1, 1, arr_size);
    }
    T build(int node_index, int left, int right) {
        if(left == right) {
            return seg[node_index] = arr?arr[left]:I;
        }
        int mid = (left + right) / 2;
        T l = build(node_index * 2, left, mid);
        T r = build(node_index * 2 + 1, mid+1, right);
        return seg[node_index] = op(l, r);
    }

    // Destructor
    ~Segtree() {delete[] seg;}

    // Features
    T _get(int st, int en, int node_index, int left, int right) {
        if(en < left or right < st) return T(I);
        if(st <= left and right <= en) return seg[node_index];
        int mid = (left + right) / 2;
        T l = _get(st, en, node_index * 2, left, mid);
        T r = _get(st, en, node_index * 2 + 1, mid+1, right);
        return op(l, r);
    }
    T _update(int pos, T v, int node_index, int left, int right) {
        if(pos < left or right < pos) return seg[node_index];
        if(left == right and left == pos) {
            arr[pos] = v;
            return seg[node_index] = v;
        }
        int mid = (left + right) / 2;
        T l = _update(pos, v, node_index * 2, left, mid);
        T r = _update(pos, v, node_index * 2 + 1, mid+1, right);
        return seg[node_index] = op(l, r);
    }

    // Interfaces
    void update(int pos, T val) {
        _update(pos, val, 1, 1, arr_size);
    }
    T get(int st, int en) {
        return _get(st, en, 1, 1, arr_size);
    }
};
using Seg = Segtree<ll, [](ll a, ll b){return a + b;}, 0LL>;


template <typename T>
concept ConvertibleToLL = std::convertible_to<T, long long>;
class modulo {
private:
    const long long default_mod = 998'244'353;
    const long long mod;
    long long val;
    void check(const modulo& other) const {
        if (this->mod != other.mod) {
            cerr << "modulo value mismatch." << endl;
            exit(1);
        }
    }
    long long mod_inverse(long long a, long long m) const {
        long long m0 = m, t, q;
        long long x0 = 0, x1 = 1;
        if (m == 1) return 0;
        while (a > 1) {
            q = a / m;
            t = m, m = a % m, a = t;
            t = x0, x0 = x1 - q * x0, x1 = t;
        }
        return (x1 < 0) ? x1 + m0 : x1;
    }
public:
    modulo() : mod(default_mod), val(0) {}
    template <ConvertibleToLL T>
    modulo(T v) : mod(default_mod), val(static_cast<long long>(v) % mod) {}
    template <ConvertibleToLL T1, ConvertibleToLL T2>
    modulo(T1 v, T2 m) : mod(static_cast<long long>(m)), val(static_cast<long long>(v) % mod) {}
    modulo(const modulo& a) : mod(a.mod), val(a.val) {}
    modulo& operator=(const modulo& a) {
        if (this != &a) {
            this->check(a);
            this->val = a.val;
        }
        return *this;
    }
    modulo& operator+=(const modulo& a) {
        this->check(a);
        this->val = (this->val + a.val) % this->mod;
        return *this;
    }
    modulo& operator-=(const modulo& a) {
        this->check(a);
        this->val = (this->val - a.val + this->mod) % this->mod;
        return *this;
    }
    modulo& operator*=(const modulo& a) {
        this->check(a);
        this->val = (this->val * a.val) % this->mod;
        return *this;
    }
    modulo& operator/=(const modulo& a) {
        this->check(a);
        this->val = (this->val * mod_inverse(a.val, this->mod)) % this->mod;
        return *this;
    }
    modulo operator+(const modulo& a) const { return modulo(*this) += a; }
    modulo operator-(const modulo& a) const { return modulo(*this) -= a; }
    modulo operator*(const modulo& a) const { return modulo(*this) *= a; }
    modulo operator/(const modulo& a) const { return modulo(*this) /= a; }
    template <ConvertibleToLL T>
    modulo& operator+=(T b) {
        this->val = (this->val + static_cast<long long>(b)) % this->mod;
        return *this;
    }
    template <ConvertibleToLL T>
    modulo& operator-=(T b) {
        this->val = (this->val - static_cast<long long>(b) + this->mod) % this->mod;
        return *this;
    }
    template <ConvertibleToLL T>
    modulo& operator*=(T b) {
        this->val = (this->val * static_cast<long long>(b)) % this->mod;
        return *this;
    }
    template <ConvertibleToLL T>
    modulo& operator/=(T b) {
        this->val = (this->val * mod_inverse(static_cast<long long>(b), this->mod)) % this->mod;
        return *this;
    }
    template <ConvertibleToLL T>
    modulo operator+(T b) const { return modulo(*this) += b; }
    template <ConvertibleToLL T>
    modulo operator-(T b) const { return modulo(*this) -= b; }
    template <ConvertibleToLL T>
    modulo operator*(T b) const { return modulo(*this) *= b; }
    template <ConvertibleToLL T>
    modulo operator/(T b) const { return modulo(*this) /= b; }
    modulo& operator++() { 
        this->val = (this->val + 1) % mod; 
        return *this; 
    }
    modulo operator++(int) { 
        modulo temp = *this; 
        this->val = (this->val + 1) % mod; 
        return temp; 
    }
    modulo& operator--() { 
        this->val = (this->val - 1 + mod) % mod; 
        return *this; 
    }
    modulo operator--(int) { 
        modulo temp = *this; 
        this->val = (this->val - 1 + mod) % mod; 
        return temp; 
    }
    bool operator==(const modulo& a) const { return this->mod == a.mod && this->val == a.val; }
    bool operator!=(const modulo& a) const { return !(*this == a); }
    bool operator<(const modulo& a) const { this->check(a); return this->val < a.val; }
    bool operator>(const modulo& a) const { this->check(a); return this->val > a.val; }
    bool operator<=(const modulo& a) const { this->check(a); return this->val <= a.val; }
    bool operator>=(const modulo& a) const { this->check(a); return this->val >= a.val; }
    template <ConvertibleToLL T>
    bool operator==(T b) const { return this->val == static_cast<long long>(b); }
    template <ConvertibleToLL T>
    bool operator!=(T b) const { return !(*this == b); }
    template <ConvertibleToLL T>
    bool operator<(T b) const { return this->val < static_cast<long long>(b); }
    template <ConvertibleToLL T>
    bool operator>(T b) const { return this->val > static_cast<long long>(b); }
    template <ConvertibleToLL T>
    bool operator<=(T b) const { return this->val <= static_cast<long long>(b); }
    template <ConvertibleToLL T>
    bool operator>=(T b) const { return this->val >= static_cast<long long>(b); }
    operator long long() const { return this->val; }
    explicit operator int() const { return static_cast<int>(this->val); }
    friend ostream& operator<<(ostream& os, const modulo& a) { return os << a.val; }
    friend istream& operator>>(istream& is, modulo& a) { long long v; is >> v; a.val = v % a.mod; return is; }
    modulo& operator[](size_t index) { return *this; }
    const modulo& operator[](size_t index) const { return *this; }
};
modulo operator"" _mod(unsigned long long v) { return modulo(v); }
using ll = modulo;