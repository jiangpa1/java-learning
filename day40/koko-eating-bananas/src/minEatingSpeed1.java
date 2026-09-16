public class minEatingSpeed1 {
    int res = 0;
    void main(){
        int[] piles = {312884470};
        System.out.println(minEatingSpeed(piles, 968709470));
    }

    public int minEatingSpeed(int[] piles, int h) {
        int high = 0;
        for (int pile : piles) {
            high = Math.max(high, pile);
        }
        return bio(piles, h, 0, high);
    }

    public int bio(int[] piles, int h, int low, int high) {
        int mid = low + high >>> 1;
        if (low > high) {return res;}
        if(isEating(piles, h, mid) == -1){
            return bio(piles, h, mid + 1, high);
        }else {
            return bio(piles, h, low, mid-1);
        }
    }

    public int isEating(int[] piles, int h, int k) {
        if (k == 0) return 1;
        int count = 0;
        for (int pile : piles) {
            count += (pile + k - 1) / k;
        }
        if(count <= h) res = k;
        return Integer.compare(h, count);
    }
}
