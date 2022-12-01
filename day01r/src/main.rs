fn p1(txt: &str) -> i32 {
    let elf_iter = txt.split("\n\n").map(|m| m.trim());
    elf_iter
        .map(|e| e.lines().map(|l| l.parse::<i32>().unwrap()).sum())
        .max()
        .unwrap()
}

fn p2(txt: &str) -> i32 {
    let elf_iter = txt.split("\n\n").map(|m| m.trim());
    let mut list: Vec<i32> = elf_iter
        .map(|e| e.lines().map(|l| l.parse::<i32>().unwrap()).sum())
        .collect();

    list.sort();
    list.iter().rev().take(3).sum()
}

fn main() {
    let txt = include_str!("../input");
    println!("Part 1: {}", p1(txt));
    println!("Part 2: {}", p2(txt));
}
