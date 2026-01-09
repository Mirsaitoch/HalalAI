package com.halalai.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "verses")
public class Verse {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sura_index", nullable = false)
    private Integer suraIndex;

    @Column(name = "sura_title", nullable = false, length = 200)
    private String suraTitle;

    @Column(name = "sura_subtitle", length = 200)
    private String suraSubtitle;

    @Column(name = "verse_number")
    private Integer verseNumber;

    @Column(name = "text", nullable = false, columnDefinition = "TEXT")
    private String text;

    public Verse() {
    }

    public Verse(Integer suraIndex, String suraTitle, String suraSubtitle, Integer verseNumber, String text) {
        this.suraIndex = suraIndex;
        this.suraTitle = suraTitle;
        this.suraSubtitle = suraSubtitle;
        this.verseNumber = verseNumber;
        this.text = text;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Integer getSuraIndex() {
        return suraIndex;
    }

    public void setSuraIndex(Integer suraIndex) {
        this.suraIndex = suraIndex;
    }

    public String getSuraTitle() {
        return suraTitle;
    }

    public void setSuraTitle(String suraTitle) {
        this.suraTitle = suraTitle;
    }

    public String getSuraSubtitle() {
        return suraSubtitle;
    }

    public void setSuraSubtitle(String suraSubtitle) {
        this.suraSubtitle = suraSubtitle;
    }

    public Integer getVerseNumber() {
        return verseNumber;
    }

    public void setVerseNumber(Integer verseNumber) {
        this.verseNumber = verseNumber;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }
}

