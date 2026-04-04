import React from 'react';

const SkeletonLoader = ({ rows = 5, columns = 6, type = 'table' }) => {
  const skeletonAnimation = `
    @keyframes shimmer {
      0% { background-position: -1000px 0; }
      100% { background-position: 1000px 0; }
    }
  `;

  const skeletonStyle = {
    background: 'linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%)',
    backgroundSize: '1000px 100%',
    animation: 'shimmer 2s infinite',
    borderRadius: '4px',
    height: '16px',
    marginBottom: '8px'
  };

  const rowStyle = {
    display: 'flex',
    gap: '16px',
    marginBottom: '16px',
    alignItems: 'center'
  };

  const cellStyle = {
    flex: 1,
    height: '40px',
    background: 'linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%)',
    backgroundSize: '1000px 100%',
    animation: 'shimmer 2s infinite',
    borderRadius: '4px'
  };

  if (type === 'table') {
    return (
      <div>
        <style>{skeletonAnimation}</style>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr>
              {Array.from({ length: columns }).map((_, i) => (
                <th key={i} style={{ padding: '12px', textAlign: 'left', borderBottom: '1px solid #e0e0e0' }}>
                  <div style={cellStyle}></div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {Array.from({ length: rows }).map((_, rowIdx) => (
              <tr key={rowIdx}>
                {Array.from({ length: columns }).map((_, colIdx) => (
                  <td key={colIdx} style={{ padding: '12px', borderBottom: '1px solid #f0f0f0' }}>
                    <div style={cellStyle}></div>
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }

  if (type === 'list') {
    return (
      <div>
        <style>{skeletonAnimation}</style>
        {Array.from({ length: rows }).map((_, idx) => (
          <div key={idx} style={rowStyle}>
            {Array.from({ length: columns }).map((_, colIdx) => (
              <div key={colIdx} style={{ ...cellStyle, flex: colIdx === 0 ? 0.5 : 1 }}></div>
            ))}
          </div>
        ))}
      </div>
    );
  }

  return (
    <div>
      <style>{skeletonAnimation}</style>
      {Array.from({ length: rows }).map((_, idx) => (
        <div key={idx} style={{ marginBottom: '16px' }}>
          {Array.from({ length: columns }).map((_, colIdx) => (
            <div key={colIdx} style={{ ...skeletonStyle, width: `${80 + Math.random() * 20}%` }}></div>
          ))}
        </div>
      ))}
    </div>
  );
};

export default SkeletonLoader;
