import pandas as pd
import openpyxl

# Caminho do arquivo
arquivo = r'c:\Users\bruno.birais\Documents\CRS-Brants\6- Cenário de Demanda 15.06.2026.xlsx'

# Ler o arquivo Excel
xl = pd.ExcelFile(arquivo)
print("=" * 80)
print("ABAS DISPONÍVEIS NA PLANILHA:")
print("=" * 80)
for i, aba in enumerate(xl.sheet_names, 1):
    print(f"{i}. {aba}")

print("\n" + "=" * 80)
print("LENDO ABA 'METODOLOGIA' (ou similar):")
print("=" * 80)

# Tentar encontrar a aba de metodologia
aba_metodologia = None
for aba in xl.sheet_names:
    if 'metodologia' in aba.lower():
        aba_metodologia = aba
        break

if aba_metodologia:
    print(f"\n✓ Encontrada: '{aba_metodologia}'")
    df = pd.read_excel(arquivo, sheet_name=aba_metodologia, header=None)
    print(f"\nDimensões: {df.shape[0]} linhas x {df.shape[1]} colunas")
    print("\n" + "-" * 80)
    print("CONTEÚDO DA METODOLOGIA:")
    print("-" * 80)
    print(df.to_string(max_rows=200, max_cols=20))
else:
    print("\n✗ Nenhuma aba com 'metodologia' no nome foi encontrada.")
    print("\nVou listar todas as abas para análise:")
    for aba in xl.sheet_names:
        print(f"\n{'=' * 80}")
        print(f"ABA: {aba}")
        print('=' * 80)
        df_temp = pd.read_excel(arquivo, sheet_name=aba, nrows=10)
        print(df_temp.to_string())
