<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Laporan Operasional</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 11px;
            color: #333;
        }
        h2 {
            margin-bottom: 0px;
        }
        .subtitle {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        .info-box {
            margin-top: 15px;
            margin-bottom: 15px;
            font-size: 11px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 6px 8px;
            text-align: left;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        .text-right {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
        .footer {
            margin-top: 30px;
            text-align: right;
            font-size: 10px;
            color: #666;
        }
    </style>
</head>
<body>

    <h2>Laporan Operasional</h2>
    <div class="subtitle">Sumber Agung Trans</div>

    <table class="info-box" style="border: none;">
        <tr style="border: none;">
            <td style="border: none; padding: 0;">
                <strong>Periode:</strong> {{ $start_date ? $start_date . ' s/d ' . $end_date : 'Semua Periode' }}<br>
                <strong>Jenis Armada:</strong> {{ $fleet_type && $fleet_type !== 'Semua' ? $fleet_type : 'Semua Jenis' }}
            </td>
            <td style="border: none; text-align: right; padding: 0;">
                <strong>Total Pemesanan:</strong> {{ $summary['total_pemesanan'] ?? 0 }}<br>
                <strong>Total Pendapatan:</strong> Rp {{ number_format($summary['total_pembayaran_masuk'] ?? 0, 0, ',', '.') }}
            </td>
        </tr>
    </table>

    <table>
        <thead>
            <tr>
                <th class="text-center" style="width: 30px;">No</th>
                <th style="width: 70px;">Tanggal</th>
                <th style="width: 60px;">Kode</th>
                <th style="width: 100px;">Pelanggan</th>
                <th style="width: 80px;">Jenis Armada</th>
                <th>Rute</th>
                <th class="text-right" style="width: 80px;">Pendapatan</th>
                <th class="text-center" style="width: 70px;">Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach($data as $index => $row)
            <tr>
                <td class="text-center">{{ $index + 1 }}</td>
                <td>{{ date('d-m-Y', strtotime($row['date'])) }}</td>
                <td>{{ $row['order_code'] }}</td>
                <td>{{ $row['customer_name'] }}</td>
                <td>{{ $row['fleet_type'] }}</td>
                <td>{{ $row['route'] }}</td>
                <td class="text-right">Rp {{ number_format($row['income'], 0, ',', '.') }}</td>
                <td class="text-center">{{ $row['status'] }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        Dicetak pada {{ $now }}
    </div>

</body>
</html>
