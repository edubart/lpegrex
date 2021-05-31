/* Used as an input example for the C11 parser. */
extern int printf(const char* format, ...);
static int fact(int n) {
    if(n == 0)
        return 1;
    else
        return n * fact(n-1);
}
int main() {
    printf("%d\n", fact(10));
    return 0;
}
