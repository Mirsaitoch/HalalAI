package com.halalai.backend.repository;

import com.halalai.backend.model.Verse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VerseRepository extends JpaRepository<Verse, Long> {
    long count();
    Page<Verse> findAllByOrderByIdAsc(Pageable pageable);
}

