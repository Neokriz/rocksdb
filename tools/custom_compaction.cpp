#include <iostream>
#include <filesystem>
#include "rocksdb/db.h"
#include "rocksdb/options.h"
#include "rocksdb/sst_file_reader.h"
#include "rocksdb/sst_file_writer.h"

namespace fs = std::filesystem;

void LoadSstFileIntoDB(const std::string& sst_file, rocksdb::DB* db) {
    rocksdb::Options options;
    rocksdb::SstFileReader reader(options);

    rocksdb::Status status = reader.Open(sst_file);
    if (!status.ok()) {
        std::cerr << "Failed to open SST file " << sst_file << ": " << status.ToString() << std::endl;
        return;
    }

    rocksdb::ReadOptions read_options;
    std::unique_ptr<rocksdb::Iterator> it(reader.NewIterator(read_options));

    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        rocksdb::Status s = db->Put(rocksdb::WriteOptions(), it->key(), it->value());
        if (!s.ok()) {
            std::cerr << "Failed to write key to DB: " << s.ToString() << std::endl;
        }
    }

    if (!it->status().ok()) {
        std::cerr << "Error reading SST file: " << it->status().ToString() << std::endl;
    }
}

void CompactDB(rocksdb::DB* db) {
    rocksdb::CompactRangeOptions compact_options;
    db->CompactRange(compact_options, nullptr, nullptr);
}

void ExportDBToSstFile(rocksdb::DB* db, const std::string& output_sst_file) {
    rocksdb::Options options;
    rocksdb::SstFileWriter sst_file_writer(rocksdb::EnvOptions(), options);

    rocksdb::Status status = sst_file_writer.Open(output_sst_file);
    if (!status.ok()) {
        std::cerr << "Failed to open output SST file: " << status.ToString() << std::endl;
        return;
    }

    rocksdb::ReadOptions read_options;
    std::unique_ptr<rocksdb::Iterator> it(db->NewIterator(read_options));

    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        status = sst_file_writer.Put(it->key(), it->value());
        if (!status.ok()) {
            std::cerr << "Failed to write to output SST file: " << status.ToString() << std::endl;
            return;
        }
    }

    status = sst_file_writer.Finish();
    if (!status.ok()) {
        std::cerr << "Failed to finish writing SST file: " << status.ToString() << std::endl;
    } else {
        std::cout << "Compaction result saved to " << output_sst_file << std::endl;
    }
}

int main() {
    // RocksDB 임시 데이터베이스 경로 설정
    std::string db_path = "./temp_rocksdb";

    rocksdb::Options options;
    options.create_if_missing = true;

    rocksdb::DB* db;
    rocksdb::Status status = rocksdb::DB::Open(options, db_path, &db);
    if (!status.ok()) {
        std::cerr << "Failed to open RocksDB: " << status.ToString() << std::endl;
        return 1;
    }

    // 현재 디렉토리의 모든 .sst 파일 로드
    for (const auto& entry : fs::directory_iterator(".")) {
        if (entry.path().extension() == ".sst") {
            std::string sst_file = entry.path().string();
            std::cout << "Loading SST file: " << sst_file << std::endl;
            LoadSstFileIntoDB(sst_file, db);
        }
    }

    // Compaction 수행
    std::cout << "Compacting DB..." << std::endl;
    CompactDB(db);
    std::cout << "Compaction completed." << std::endl;

    // Compaction 결과를 새로운 SST 파일로 저장
    std::string output_sst_file = "compacted_result.sst";
    ExportDBToSstFile(db, output_sst_file);

    delete db;

    // 임시 데이터베이스 삭제
    fs::remove_all(db_path);

    return 0;
}