/**
   Had to write this because atleast on Ubuntu 18.04 sort and join don't seem
   to agrree on whether the file is sorted or not.
   Sort produces sequences of the form
   /a/b/cd
   /a/b/c
   in that order and join doesn't like it.
   Upon padding with some char (eg @) it becomes
   /a/b/c@@
   /a/b/cd@
   and join doesn't like this either.

   This util joins using hash-maps (data should fit in memory).
 */
#include <iostream>
#include <fstream>
#include <unordered_map>
#include <string>

std::unordered_map<std::string, std::string> key_map(const char* file_path) {
  std::ifstream s(file_path);
  std::unordered_map<std::string, std::string> m;
  std::string line;
  while (std::getline(s, line)) {
    auto offset = line.find(" ");
    if (offset == std::string::npos) {
      offset = line.length();
    }
    auto key = line.substr(0, offset);
    m.insert({key, line});
  }
  return m;
}

int main(int argc, char** argv) {
  if (argc != 6) {
    std::cerr << "Usage: hash_join <src file0> <src file1> "
      "<dest file present_in_both> "
      "<dest file for missing in file0> "
      "<dest file for missing in file1> "
      "(join is done by first column)\n";
    return 1;
  }
  auto m0 = key_map(argv[1]);
  auto m1 = key_map(argv[2]);

  std::ofstream present_in_both(argv[3], std::ios::trunc | std::ios::out);
  std::ofstream missing_in_m0(argv[4], std::ios::trunc | std::ios::out);
  std::ofstream missing_in_m1(argv[5], std::ios::trunc | std::ios::out);

  for (const auto& e : m0) {
    auto it = m1.find(e.first);
    if (it == m1.end()) {
      missing_in_m1 << e.second << "\n";
      continue;
    }
    present_in_both << e.second << " " << it->second << "\n";
  }
  for (const auto& e : m1) {
    auto it = m0.find(e.first);
    if (it == m0.end()) {
      missing_in_m0 << e.second << "\n";
    }
  }

  return 0;
}
