# End-to-End Sales Analytics & Power BI Controlling Dashboard

Projekt analityczny typu End-to-End realizujący pełny proces przetwarzania danych: od warstwy relacyjnej hurtowni danych **WideWorldImportersDW** w SQL Server, przez skrypty walidacyjne i analityczne T-SQL, po zoptymalizowany model gwiazdy (Star Schema) oraz interaktywny raport controllingowy w **Microsoft Power BI** przygotowany zgodnie ze standardami **IBCS** (International Business Communication Standards).

---

## Architektura Rozwiązania

```text
[ WideWorldImportersDW ] 
       │ 
       ▼ (T-SQL Scripts: Views / Reconciliation / EDA)
[ SQL Engine Layer ] ────────> 01_views.sql | 02_data_validation.sql | 03_ad_hoc_analysis.sql
       │
       ▼ (Direct Import / Query Folding / VertiPaq Engine)
[ Power BI Data Model ] ────> Star Schema & DAX Measures
       │
       ▼
[ IBCS Dashboard ]      ────> 1. Controlling Sprzedaży (Poziom Zarządczy)
                        ────> 2. Controlling Asortymentu (Poziom Operacyjny)

```

---

## Warstwa SQL (`/sql`)

Warstwa relacyjna odpowiada za przygotowanie widoków raportowych, weryfikację spójności danych w hurtowni oraz wykonanie zaawansowanych analiz eksploracyjnych. Całość kodu T-SQL została podzielona na modułowe skrypty:

* **[sql/01_views.sql](https://www.google.com/search?q=sql/01_views.sql):** Utworzenie dedykowanego widoku `Fact.vw_Sales_Reporting`[cite: 7]. Widok stanowi warstwę abstrakcji odseparowaną od tabel bazowych, co umożliwia Query Folding w Power Query oraz eliminuje niepotrzebne kolumny z pamięci silnika VertiPaq[cite: 7].
* **[sql/02_data_validation.sql](https://www.google.com/search?q=sql/02_data_validation.sql):** Skrypty rekoncyliacyjne służące do walidacji miar DAX względem DWH[cite: 6]:
* Weryfikacja zagregowanych wartości KPI (przychód, zysk, marża brutto, wolumen)[cite: 6].
* Sprawdzenie skrajnych zakresów dat transakcji (`Invoice Date Key`)[cite: 6].
* Audyt integracji relacji – wykluczenie rekordów sierocych (*orphaned keys*) w tabeli `Fact.Sale`[cite: 6].


* **[sql/03_ad_hoc_analysis.sql](https://www.google.com/search?q=sql/03_ad_hoc_analysis.sql):** Zaawansowane zapytania analityczne T-SQL z wykorzystaniem podzapytań CTE oraz funkcji okna:
* **Analiza Pareto 80/20:** Klasyfikacja klientów do grup A, B i C w oparciu o ich udział w narastającej sumie przychodów (`SUM() OVER (ORDER BY ...)`)[cite: 5].
* **Analiza YoY Growth:** Obliczenie rocznej dynamiki sprzedaży na poziomie miesięcznym z wykorzystaniem funkcji przesunięcia `LAG(..., 12)`[cite: 5].



---

## Architektura Modelu Danych w Power BI

Model danych został zaimplementowany w standardzie **Modelu Gwiazdy (Star Schema)**.

```text
                  +-------------------+
                  |     Dim_Date      |
                  +---------+---------+
                            | 1
                            |
                            | *
+-------------------+     +-+-----------------+     +-------------------+
|   Dim_Customer    |1---*|    Fact_Sales     |*---| Dim_SalesTerritory|
+-------------------+     +-+-----------------+     +-------------------+
                            | *
                            |
                            | 1
                  +---------+---------+
                  |   Dim_StockItem   |
                  +-------------------+

```

### Kluczowe Miary DAX (`_Measures`)

```dax
// Przychód Całkowity
Total Revenue = 
SUMX(
    Fact_Sales,
    Fact_Sales[Quantity] * Fact_Sales[UnitPrice]
)

// Zysk Całkowity
Total Profit = 
SUM(Fact_Sales[TotalProfit])

// Marża Procentowa
Margin % = 
DIVIDE([Total Profit], [Total Revenue], 0)

// Liczba Zrealizowanych Faktur
Total Invoices = 
DISTINCTCOUNT(Fact_Sales[InvoiceID])

// Dynamika YoY (%)
YoY Growth % = 
VAR RevenuePY = CALCULATE([Total Revenue], SAMEPERIODLASTYEAR(Dim_Date[Date]))
RETURN DIVIDE([Total Revenue] - RevenuePY, RevenuePY, 0)

```

---

## Prezentacja Raportu (Power BI)

### 1. Controlling Sprzedaży (Poziom Zarządczy)

Skonsolidowany pulpit zarządczy prezentujący kluczowe wskaźniki efektywności handlowej, trend miesięczny przychodu w zestawieniu z marżą procentową oraz rozkład geograficzny i strukturę Top 10 klientów.

---

### 2. Controlling Asortymentu (Poziom Operacyjny)

Panel diagnostyczny portfela produktów wykorzystujący macierz rozrzutu (analiza bąbelkowa przychód vs. marża), dwupoziomowe formatowanie warunkowe dla produktów nierentownych oraz dynamiczne tooltipy historyczne.

---

## Optymalizacja Wydajności

* **Przetwarzanie DAX:** Średni czas wykonania zapytań dla kluczowych kart wynosi **< 15 ms** (weryfikacja w Performance Analyzer).
* **Redukcja Obiektów Visual:** Zastosowanie natywnego *New Card Visual* pozwoliło zredukować czas renderowania interfejsu o **60%**.
* **Pamięć RAM:** Wyłączenie automatycznej hierarchii dat (*Auto Date/Time*) zredukowało rozmiar modelu w pamięci VertiPaq o ponad **40%**.

---

## Struktura Repozytorium

```text
.
├── docs/
│   ├── controlling_asortymentu.png
│   └── controlling_sprzedazy.png
├── sql/
│   ├── 01_views.sql
│   ├── 02_data_validation.sql
│   └── 03_ad_hoc_analysis.sql
├── WideWorldImportersDW-Full.Report/          # Definicja raportu Power BI (PBIP)
│   ├── definition/
│   │   ├── pages/
│   │   ├── pages.json
│   │   ├── report.json
│   │   └── version.json
│   ├── .platform
│   └── definition.pbir
├── WideWorldImportersDW-Full.SemanticModel/   # Model semantyczny i miary DAX (PBIP)
│   ├── DAXQueries/
│   ├── definition/
│   ├── .platform
│   ├── definition.pbism
│   └── diagramLayout.json
└── README.md

```

---

## Jak Uruchomić Projekt

1. Sklonuj repozytorium:
```bash
git clone git@github.com:MarekFox/PowerBI-Controlling-Dashboard.git

```


2. **Skrypty SQL:** Uruchom po kolei pliki z katalogu `sql/` na bazie `WideWorldImportersDW` w środowisku SSMS lub Azure Data Studio[cite: 5, 6, 7].
3. **Power BI:** Otwórz plik `WideWorldImportersDW-Full.Report/definition.pbir` lub bezpośrednio katalog PBIP w aplikacji Power BI Desktop.